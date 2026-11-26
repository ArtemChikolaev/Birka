package main

import (
	"database/sql"
	"errors"
)

// Existing sessions and challenges keep their keys. Old clients can still use
// the email endpoints and accounts can now own one verified method per channel.
func initSchema(db *sql.DB) error {
	if _, err := db.Exec("PRAGMA foreign_keys=ON; PRAGMA busy_timeout=5000"); err != nil {
		return err
	}
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var version int
	if err = tx.QueryRow("PRAGMA user_version").Scan(&version); err != nil {
		return err
	}
	if version == 1 {
		return tx.Commit()
	}
	if version != 0 {
		return errors.New("unsupported identity database version")
	}
	var old bool
	if err = tx.QueryRow("SELECT EXISTS(SELECT 1 FROM sqlite_master WHERE type='table' AND name='accounts')").Scan(&old); err != nil {
		return err
	}
	if old {
		if _, err = tx.Exec(`ALTER TABLE accounts RENAME TO old_accounts;
    ALTER TABLE sessions RENAME TO old_sessions; ALTER TABLE challenges RENAME TO old_challenges;
    DROP INDEX IF EXISTS session_expiry;`); err != nil {
			return err
		}
	}
	if _, err = tx.Exec(`
 CREATE TABLE accounts(id TEXT PRIMARY KEY);
 CREATE TABLE methods(lookup TEXT PRIMARY KEY, channel TEXT NOT NULL, address BLOB NOT NULL, account TEXT NOT NULL REFERENCES accounts(id), UNIQUE(account,channel));
 CREATE TABLE sessions(digest BLOB PRIMARY KEY, account TEXT NOT NULL REFERENCES accounts(id), expires INTEGER NOT NULL);
 CREATE INDEX session_expiry ON sessions(expires);
 CREATE TABLE challenges(lookup TEXT PRIMARY KEY, channel TEXT NOT NULL, address BLOB NOT NULL, id TEXT UNIQUE NOT NULL, digest BLOB NOT NULL, issued INTEGER NOT NULL, attempts INTEGER NOT NULL DEFAULT 0, link_session BLOB);
 CREATE TABLE registrations(digest BLOB PRIMARY KEY, lookup TEXT UNIQUE NOT NULL, address BLOB NOT NULL, expires INTEGER NOT NULL);
 CREATE TABLE IF NOT EXISTS quotas(kind TEXT NOT NULL, source TEXT NOT NULL, started INTEGER NOT NULL, used INTEGER NOT NULL, PRIMARY KEY(kind,source));
 `); err != nil {
		return err
	}
	if old {
		if _, err = tx.Exec(`INSERT INTO accounts SELECT email FROM old_accounts;
    INSERT INTO methods SELECT email,'email',address,email FROM old_accounts;
    INSERT INTO sessions SELECT digest,email,expires FROM old_sessions;
    INSERT INTO challenges SELECT email,'email',address,id,digest,issued,attempts,NULL FROM old_challenges;
    DROP TABLE old_sessions; DROP TABLE old_challenges; DROP TABLE old_accounts;`); err != nil {
			return err
		}
	}
	if _, err = tx.Exec("PRAGMA user_version=1"); err != nil {
		return err
	}
	return tx.Commit()
}
