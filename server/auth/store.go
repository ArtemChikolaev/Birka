// Package main serves Birka's optional identity. Financial records never enter this database.
package main

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/hkdf"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"errors"
	"fmt"
	"math/big"
	"time"

	_ "modernc.org/sqlite"
)

var errLimit = errors.New("request limit")
var errCode = errors.New("invalid or expired code")

const sessionAge = 30 * 24 * time.Hour
const codeAge = 10 * time.Minute

type accounts struct {
	db        *sql.DB
	key       []byte
	now       func() time.Time
	addresses cipher.AEAD
}

func openAccounts(path string, key []byte) (*accounts, error) {
	addressKey, err := hkdf.Key(sha256.New, key, nil, "Birka account addresses v1", 32)
	if err != nil {
		return nil, err
	}
	block, err := aes.NewCipher(addressKey)
	if err != nil {
		return nil, err
	}
	addresses, err := cipher.NewGCMWithRandomNonce(block)
	if err != nil {
		return nil, err
	}
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(1)
	_, err = db.Exec(`
PRAGMA foreign_keys=ON;
PRAGMA busy_timeout=5000;
CREATE TABLE IF NOT EXISTS accounts (email TEXT PRIMARY KEY, address BLOB NOT NULL);
CREATE TABLE IF NOT EXISTS challenges (email TEXT PRIMARY KEY, address BLOB NOT NULL, id TEXT UNIQUE NOT NULL, digest BLOB NOT NULL, issued INTEGER NOT NULL, attempts INTEGER NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS sessions (digest BLOB PRIMARY KEY, email TEXT NOT NULL REFERENCES accounts(email), expires INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS quotas (kind TEXT NOT NULL, source TEXT NOT NULL, started INTEGER NOT NULL, used INTEGER NOT NULL, PRIMARY KEY(kind,source));
CREATE INDEX IF NOT EXISTS session_expiry ON sessions(expires);
`)
	if err != nil {
		db.Close()
		return nil, err
	}
	return &accounts{db: db, key: key, now: time.Now, addresses: addresses}, nil
}

func randomToken() string {
	var b [32]byte
	rand.Read(b[:])
	return base64.RawURLEncoding.EncodeToString(b[:])
}

func (a *accounts) digestCode(id, code string) []byte {
	mac := hmac.New(sha256.New, a.key)
	fmt.Fprint(mac, id, ":", code)
	return mac.Sum(nil)
}

// A database backup contains neither the mailbox nor the network address.
func (a *accounts) lookup(kind, value string) string {
	mac := hmac.New(sha256.New, a.key)
	fmt.Fprint(mac, "lookup:", kind, ":", value)
	return base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
}

func quota(tx *sql.Tx, kind, source string, now int64, max int) error {
	// One anchored hour. A rejected request never extends the window.
	r, err := tx.Exec(`INSERT INTO quotas VALUES(?,?,?,1)
       ON CONFLICT(kind,source) DO UPDATE SET
       used=CASE WHEN started<=? THEN 1 ELSE used+1 END,
       started=CASE WHEN started<=? THEN excluded.started ELSE started END
       WHERE started<=? OR used<?`, kind, source, now, now-3600, now-3600, now-3600, max)
	if err != nil {
		return err
	}
	n, err := r.RowsAffected()
	if err == nil && n == 0 {
		return errLimit
	}
	return err
}

func (a *accounts) issue(ctx context.Context, email, ip string) (id, code string, err error) {
	tx, err := a.db.BeginTx(ctx, nil)
	if err != nil {
		return "", "", err
	}
	defer tx.Rollback()
	now := a.now().Unix()
	mailbox := a.lookup("email", email)
	if err = quota(tx, "ip", a.lookup("ip", ip), now, 30); err != nil {
		return "", "", err
	}
	if err = quota(tx, "email", mailbox, now, 5); err != nil {
		return "", "", err
	}
	id = randomToken()
	number, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", "", err
	}
	code = fmt.Sprintf("%06d", number.Int64())
	address := a.addresses.Seal(nil, nil, []byte(email), []byte(mailbox))
	r, err := tx.Exec(`INSERT INTO challenges(email,address,id,digest,issued) VALUES(?,?,?,?,?)
      ON CONFLICT(email) DO UPDATE SET id=excluded.id,digest=excluded.digest,issued=excluded.issued,attempts=0
      WHERE issued<=?`, mailbox, address, id, a.digestCode(id, code), now, now-60)
	if err != nil {
		return "", "", err
	}
	n, err := r.RowsAffected()
	if err != nil {
		return "", "", err
	}
	if n == 0 {
		return "", "", errLimit
	}
	return id, code, tx.Commit()
}

func (a *accounts) verify(ctx context.Context, id, code string) (email, token string, err error) {
	tx, err := a.db.BeginTx(ctx, nil)
	if err != nil {
		return "", "", err
	}
	defer tx.Rollback()
	var digest, address []byte
	var mailbox string
	err = tx.QueryRow(`UPDATE challenges SET attempts=attempts+1 WHERE id=? AND issued>? AND attempts<5 RETURNING email,address,digest`, id, a.now().Add(-codeAge).Unix()).Scan(&mailbox, &address, &digest)
	if errors.Is(err, sql.ErrNoRows) {
		return "", "", errCode
	}
	if err != nil {
		return "", "", err
	}
	if !hmac.Equal(digest, a.digestCode(id, code)) {
		if err := tx.Commit(); err != nil {
			return "", "", err
		}
		return "", "", errCode
	}
	plain, err := a.addresses.Open(nil, nil, address, []byte(mailbox))
	if err != nil {
		return "", "", err
	}
	email = string(plain)
	if _, err = tx.Exec("DELETE FROM challenges WHERE id=?", id); err != nil {
		return "", "", err
	}
	if _, err = tx.Exec("INSERT INTO accounts(email,address) VALUES(?,?) ON CONFLICT DO NOTHING", mailbox, address); err != nil {
		return "", "", err
	}
	token = randomToken()
	hash := sha256.Sum256([]byte(token))
	if _, err = tx.Exec("INSERT INTO sessions VALUES(?,?,?)", hash[:], mailbox, a.now().Add(sessionAge).Unix()); err != nil {
		return "", "", err
	}
	return email, token, tx.Commit()
}

func (a *accounts) cleanup() error {
	now := a.now()
	tx, err := a.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err = tx.Exec("DELETE FROM challenges WHERE issued<=?", now.Add(-codeAge).Unix()); err != nil {
		return err
	}
	if _, err = tx.Exec("DELETE FROM sessions WHERE expires<=?", now.Unix()); err != nil {
		return err
	}
	if _, err = tx.Exec("DELETE FROM quotas WHERE started<=?", now.Add(-time.Hour).Unix()); err != nil {
		return err
	}
	return tx.Commit()
}
