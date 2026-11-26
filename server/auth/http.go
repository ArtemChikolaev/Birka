package main

import (
	"crypto/sha256"
	"database/sql"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"net/mail"
	"regexp"
	"strings"
)

type application struct {
	accounts *accounts
	send     func(email, code, language string) error
	origin   string
	local    bool
	proxy    bool
}

func reply(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if body != nil {
		json.NewEncoder(w).Encode(body)
	}
}

func decode(w http.ResponseWriter, r *http.Request, dst any) bool {
	if strings.TrimSpace(strings.SplitN(r.Header.Get("Content-Type"), ";", 2)[0]) != "application/json" {
		reply(w, 415, nil)
		return false
	}
	dec := json.NewDecoder(http.MaxBytesReader(w, r.Body, 4096))
	dec.DisallowUnknownFields()
	if dec.Decode(dst) != nil || dec.Decode(new(any)) != io.EOF {
		reply(w, 400, nil)
		return false
	}
	return true
}

func (app *application) handler() http.Handler {
	m := http.NewServeMux()
	m.HandleFunc("POST /v1/code", app.request)
	m.HandleFunc("POST /v1/verify", app.verify)
	m.HandleFunc("GET /v1/session", app.session)
	m.HandleFunc("POST /v1/logout", app.logout)
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Vary", "Origin")
		origin := r.Header.Get("Origin")
		if origin != "" {
			if origin != app.origin {
				reply(w, 403, nil)
				return
			}
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Set("Access-Control-Allow-Credentials", "true")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, X-Birka-Client")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		}
		if r.Method == "OPTIONS" {
			reply(w, 204, nil)
			return
		}
		mode := r.Header.Get("X-Birka-Client")
		if mode != "web" && mode != "native" || origin != "" && mode != "web" {
			reply(w, 403, nil)
			return
		}
		m.ServeHTTP(w, r)
	})
}

func validEmail(value string) bool {
	if len(value) > 254 || strings.ContainsAny(value, "\r\n") {
		return false
	}
	address, err := mail.ParseAddress(value)
	return err == nil && address.Address == value && !strings.ContainsAny(value, " <>\t")
}

func (app *application) request(w http.ResponseWriter, r *http.Request) {
	var in struct{ Email, Language string }
	if !decode(w, r, &in) {
		return
	}
	email := strings.ToLower(strings.TrimSpace(in.Email))
	if !validEmail(email) {
		reply(w, 400, nil)
		return
	}
	ip, _, _ := net.SplitHostPort(r.RemoteAddr)
	if app.proxy && net.ParseIP(ip).IsLoopback() {
		if remote := net.ParseIP(r.Header.Get("X-Real-IP")); remote != nil {
			ip = remote.String()
		}
	}
	id, code, err := app.accounts.issue(r.Context(), email, ip)
	if errors.Is(err, errLimit) {
		reply(w, 429, nil)
		return
	}
	if err != nil {
		reply(w, 503, nil)
		return
	}
	if err = app.send(email, code, in.Language); err != nil {
		// Only invalidate the challenge whose delivery failed.
		app.accounts.db.Exec("DELETE FROM challenges WHERE id=?", id)
		reply(w, 503, nil)
		return
	}
	reply(w, 200, map[string]string{"challenge": id})
}

var digits = regexp.MustCompile(`^[0-9]{6}$`)

func (app *application) verify(w http.ResponseWriter, r *http.Request) {
	var in struct{ Challenge, Code string }
	if !decode(w, r, &in) {
		return
	}
	if len(in.Challenge) != 43 || !digits.MatchString(in.Code) {
		reply(w, 401, nil)
		return
	}
	email, token, err := app.accounts.verify(r.Context(), in.Challenge, in.Code)
	if errors.Is(err, errCode) {
		reply(w, 401, nil)
		return
	}
	if err != nil {
		reply(w, 503, nil)
		return
	}
	out := map[string]string{"email": email}
	if r.Header.Get("X-Birka-Client") == "web" {
		app.cookie(w, token, int(sessionAge.Seconds()))
	} else {
		out["token"] = token
	}
	reply(w, 200, out)
}

func (app *application) cookieName() string {
	if app.local {
		return "birka_dev_session"
	}
	return "__Host-birka_session"
}
func (app *application) cookie(w http.ResponseWriter, value string, age int) {
	http.SetCookie(w, &http.Cookie{Name: app.cookieName(), Value: value, Path: "/", HttpOnly: true, Secure: !app.local, SameSite: http.SameSiteLaxMode, MaxAge: age})
}
func (app *application) token(r *http.Request) string {
	if r.Header.Get("X-Birka-Client") == "web" {
		if c, err := r.Cookie(app.cookieName()); err == nil {
			return c.Value
		}
	} else if token, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer "); ok {
		return token
	}
	return ""
}
func (app *application) session(w http.ResponseWriter, r *http.Request) {
	hash := sha256.Sum256([]byte(app.token(r)))
	var mailbox string
	var address []byte
	err := app.accounts.db.QueryRowContext(r.Context(), "SELECT accounts.email,accounts.address FROM sessions JOIN accounts USING(email) WHERE digest=? AND expires>?", hash[:], app.accounts.now().Unix()).Scan(&mailbox, &address)
	if errors.Is(err, sql.ErrNoRows) {
		reply(w, 401, nil)
		return
	}
	if err != nil {
		reply(w, 503, nil)
		return
	}
	plain, err := app.accounts.addresses.Open(nil, nil, address, []byte(mailbox))
	if err != nil {
		reply(w, 503, nil)
		return
	}
	reply(w, 200, map[string]string{"email": string(plain)})
}
func (app *application) logout(w http.ResponseWriter, r *http.Request) {
	hash := sha256.Sum256([]byte(app.token(r)))
	if _, err := app.accounts.db.ExecContext(r.Context(), "DELETE FROM sessions WHERE digest=?", hash[:]); err != nil {
		reply(w, 503, nil)
		return
	}
	if r.Header.Get("X-Birka-Client") == "web" {
		app.cookie(w, "", -1)
	}
	reply(w, 204, nil)
}
