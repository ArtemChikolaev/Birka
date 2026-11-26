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
	err = initSchema(db)
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

func quota(tx *sql.Tx, kind, source string, now int64, window time.Duration, max int) error {
	// A rejected request never extends the window.
	cutoff := now - int64(window.Seconds())
	r, err := tx.Exec(`INSERT INTO quotas VALUES(?,?,?,1)
       ON CONFLICT(kind,source) DO UPDATE SET
       used=CASE WHEN started<=? THEN 1 ELSE used+1 END,
       started=CASE WHEN started<=? THEN excluded.started ELSE started END
       WHERE started<=? OR used<?`, kind, source, now, cutoff, cutoff, cutoff, max)
	if err != nil {
		return err
	}
	n, err := r.RowsAffected()
	if err == nil && n == 0 {
		return errLimit
	}
	return err
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
	if _, err = tx.Exec("DELETE FROM registrations WHERE expires<=?", now.Unix()); err != nil {
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

const (
	emailChannel    = "email"
	telegramChannel = "telegram"
)

var errSession = errors.New("session expired")
var errOccupied = errors.New("method already linked")

func tokenDigest(token string) []byte {
	sum := sha256.Sum256([]byte(token))
	return sum[:]
}

func sessionOwner(tx *sql.Tx, digest []byte, now int64) (string, error) {
	var owner string
	err := tx.QueryRow("SELECT account FROM sessions WHERE digest=? AND expires>?", digest, now).Scan(&owner)
	if errors.Is(err, sql.ErrNoRows) {
		err = errSession
	}
	return owner, err
}

func (a *accounts) issue(ctx context.Context, channel, value, ip string, linkSession []byte, telegramLimit int) (id, code string, err error) {
	tx, err := a.db.BeginTx(ctx, nil)
	if err != nil {
		return "", "", err
	}
	defer tx.Rollback()
	now := a.now().Unix()
	lookup := a.lookup(channel, value)
	if linkSession != nil {
		owner, err := sessionOwner(tx, linkSession, now)
		if err != nil {
			return "", "", err
		}
		var hasMethod bool
		if err = tx.QueryRow("SELECT EXISTS(SELECT 1 FROM methods WHERE account=? AND channel=?)", owner, channel).Scan(&hasMethod); err != nil {
			return "", "", err
		}
		if hasMethod {
			return "", "", errOccupied
		}
	}
	if err = quota(tx, "ip", a.lookup("ip", ip), now, time.Hour, 30); err != nil {
		return "", "", err
	}
	if err = quota(tx, channel, lookup, now, time.Hour, 5); err != nil {
		return "", "", err
	}
	if channel == telegramChannel {
		if err = quota(tx, "telegram-resend", lookup, now, time.Minute, 1); err != nil {
			return "", "", err
		}
		if err = quota(tx, "telegram-service", "all", now, time.Hour, telegramLimit); err != nil {
			return "", "", err
		}
	}
	id = randomToken()
	number, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		return "", "", err
	}
	code = fmt.Sprintf("%06d", number.Int64())
	address := a.addresses.Seal(nil, nil, []byte(value), []byte(lookup))
	r, err := tx.Exec(`INSERT INTO challenges(lookup,channel,address,id,digest,issued,link_session) VALUES(?,?,?,?,?,?,?)
  ON CONFLICT(lookup) DO UPDATE SET id=excluded.id,digest=excluded.digest,issued=excluded.issued,attempts=0,link_session=excluded.link_session
  WHERE issued<=?`, lookup, channel, address, id, a.digestCode(id, code), now, linkSession, now-60)
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
	if _, err = tx.Exec("DELETE FROM registrations WHERE lookup=?", lookup); err != nil {
		return "", "", err
	}
	return id, code, tx.Commit()
}

type verification struct {
	profile      map[string]string
	token        string
	registration string
}

func (a *accounts) profile(tx *sql.Tx, owner string) (map[string]string, error) {
	rows, err := tx.Query("SELECT lookup,channel,address FROM methods WHERE account=?", owner)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[string]string{}
	for rows.Next() {
		var lookup, channel string
		var address []byte
		if err = rows.Scan(&lookup, &channel, &address); err != nil {
			return nil, err
		}
		plain, err := a.addresses.Open(nil, nil, address, []byte(lookup))
		if err != nil {
			return nil, err
		}
		value := string(plain)
		if channel == telegramChannel {
			value = "•••• " + value[len(value)-4:]
		}
		out[channel] = value
	}
	return out, rows.Err()
}

func (a *accounts) finish(tx *sql.Tx, owner string, newSession bool) (v verification, err error) {
	v.profile, err = a.profile(tx, owner)
	if err != nil {
		return v, err
	}
	if newSession {
		v.token = randomToken()
		_, err = tx.Exec("INSERT INTO sessions VALUES(?,?,?)", tokenDigest(v.token), owner, a.now().Add(sessionAge).Unix())
		if err != nil {
			return v, err
		}
	}
	return v, tx.Commit()
}

func insertIdentity(tx *sql.Tx, channel, lookup string, address []byte) (string, error) {
	owner := randomToken()
	if _, err := tx.Exec("INSERT INTO accounts VALUES(?)", owner); err != nil {
		return "", err
	}
	_, err := tx.Exec("INSERT INTO methods VALUES(?,?,?,?)", lookup, channel, address, owner)
	return owner, err
}

func (a *accounts) verify(ctx context.Context, id, code, token string) (v verification, err error) {
	tx, err := a.db.BeginTx(ctx, nil)
	if err != nil {
		return v, err
	}
	defer tx.Rollback()
	var lookup, channel string
	var digest, address, binding []byte
	var issued int64
	now := a.now().Unix()
	err = tx.QueryRow(`UPDATE challenges SET attempts=attempts+1 WHERE id=? AND issued>? AND attempts<5 AND (link_session IS NULL OR link_session=?) RETURNING lookup,channel,address,digest,issued,link_session`, id, now-int64(codeAge.Seconds()), tokenDigest(token)).Scan(&lookup, &channel, &address, &digest, &issued, &binding)
	if errors.Is(err, sql.ErrNoRows) {
		return v, errCode
	}
	if err != nil {
		return v, err
	}
	if !hmac.Equal(digest, a.digestCode(id, code)) {
		if err = tx.Commit(); err != nil {
			return v, err
		}
		return v, errCode
	}
	if _, err = tx.Exec("DELETE FROM challenges WHERE id=?", id); err != nil {
		return v, err
	}
	var owner string
	err = tx.QueryRow("SELECT account FROM methods WHERE lookup=?", lookup).Scan(&owner)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return v, err
	}
	if binding != nil {
		current, err := sessionOwner(tx, binding, now)
		if err != nil {
			return v, err
		}
		// Neither another account's method nor an existing method of the same
		// channel on this account can be replaced.
		if _, err = tx.Exec("INSERT INTO methods VALUES(?,?,?,?) ON CONFLICT DO NOTHING", lookup, channel, address, current); err != nil {
			return v, err
		}
		var linked bool
		if err = tx.QueryRow("SELECT EXISTS(SELECT 1 FROM methods WHERE lookup=? AND account=?)", lookup, current).Scan(&linked); err != nil {
			return v, err
		}
		if !linked {
			if err = tx.Commit(); err != nil {
				return v, err
			}
			return v, errOccupied
		}
		return a.finish(tx, current, false)
	}
	if owner == "" && channel == telegramChannel {
		v.registration = randomToken()
		_, err = tx.Exec("INSERT INTO registrations VALUES(?,?,?,?)", tokenDigest(v.registration), lookup, address, issued+int64(codeAge.Seconds()))
		if err != nil {
			return v, err
		}
		return v, tx.Commit()
	}
	if owner == "" {
		owner, err = insertIdentity(tx, channel, lookup, address)
		if err != nil {
			return v, err
		}
	}
	return a.finish(tx, owner, true)
}

func (a *accounts) register(ctx context.Context, proof string) (v verification, err error) {
	tx, err := a.db.BeginTx(ctx, nil)
	if err != nil {
		return v, err
	}
	defer tx.Rollback()
	var lookup string
	var address []byte
	err = tx.QueryRow("DELETE FROM registrations WHERE digest=? AND expires>? RETURNING lookup,address", tokenDigest(proof), a.now().Unix()).Scan(&lookup, &address)
	if errors.Is(err, sql.ErrNoRows) {
		return v, errCode
	}
	if err != nil {
		return v, err
	}
	owner, err := insertIdentity(tx, telegramChannel, lookup, address)
	if err != nil {
		return v, err
	}
	return a.finish(tx, owner, true)
}
