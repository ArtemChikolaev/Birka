package main

import (
	"context"
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
	accounts      *accounts
	send          func(email, code, language string) error
	origin        string
	local         bool
	proxy         bool
	telegram      func(context.Context, string, string) error
	telegramLimit int
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
	m.HandleFunc("GET /v1/methods", func(w http.ResponseWriter, r *http.Request) {
		reply(w, 200, map[string]bool{"email": app.send != nil, "telegram": app.telegram != nil})
	})
	m.HandleFunc("POST /v1/register", app.register)
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
	var in struct {
		Email, Phone, Language string
		Consent, Link          bool
	}
	if !decode(w, r, &in) {
		return
	}
	channel := emailChannel
	value := strings.ToLower(strings.TrimSpace(in.Email))
	if in.Phone != "" {
		channel = telegramChannel
		value = normalizedPhone(in.Phone)
		if in.Email != "" || !in.Consent || !phoneNumber.MatchString(value) {
			reply(w, 400, nil)
			return
		}
		if app.telegram == nil {
			reply(w, 503, nil)
			return
		}
	} else {
		if !validEmail(value) {
			reply(w, 400, nil)
			return
		}
		if app.send == nil {
			reply(w, 503, nil)
			return
		}
	}
	var binding []byte
	if in.Link {
		binding = tokenDigest(app.token(r))
	}
	ip, _, _ := net.SplitHostPort(r.RemoteAddr)
	if app.proxy && net.ParseIP(ip).IsLoopback() {
		if remote := net.ParseIP(r.Header.Get("X-Real-IP")); remote != nil {
			ip = remote.String()
		}
	}
	id, code, err := app.accounts.issue(r.Context(), channel, value, ip, binding, app.telegramLimit)
	if err != nil {
		accountError(w, err)
		return
	}
	if channel == telegramChannel {
		err = app.telegram(r.Context(), value, code)
	} else {
		err = app.send(value, code, in.Language)
	}
	if err != nil {
		app.accounts.db.Exec("DELETE FROM challenges WHERE id=?", id)
		if errors.Is(err, errLimit) {
			reply(w, 429, nil)
		} else {
			reply(w, 502, nil)
		}
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
	result, err := app.accounts.verify(r.Context(), in.Challenge, in.Code, app.token(r))
	app.verified(w, r, result, err)
}

func accountError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, errLimit):
		reply(w, 429, nil)
	case errors.Is(err, errCode):
		reply(w, 401, nil)
	case errors.Is(err, errSession):
		reply(w, 401, map[string]string{"error": "session"})
	case errors.Is(err, errOccupied):
		reply(w, 409, nil)
	default:
		reply(w, 503, nil)
	}
}

func (app *application) register(w http.ResponseWriter, r *http.Request) {
	var in struct{ Registration string }
	if !decode(w, r, &in) {
		return
	}
	if len(in.Registration) != 43 {
		reply(w, 401, nil)
		return
	}
	result, err := app.accounts.register(r.Context(), in.Registration)
	app.verified(w, r, result, err)
}

func (app *application) verified(w http.ResponseWriter, r *http.Request, result verification, err error) {
	if err != nil {
		accountError(w, err)
		return
	}
	if result.registration != "" {
		reply(w, 200, map[string]string{"registration": result.registration})
		return
	}
	if result.token != "" {
		if r.Header.Get("X-Birka-Client") == "web" {
			app.cookie(w, result.token, int(sessionAge.Seconds()))
		} else {
			result.profile["token"] = result.token
		}
	}
	reply(w, 200, result.profile)
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
	a := app.accounts
	tx, err := a.db.BeginTx(r.Context(), nil)
	if err != nil {
		accountError(w, err)
		return
	}
	defer tx.Rollback()
	owner, err := sessionOwner(tx, tokenDigest(app.token(r)), a.now().Unix())
	if err != nil {
		if errors.Is(err, errSession) {
			reply(w, 401, nil)
		} else {
			accountError(w, err)
		}
		return
	}
	profile, err := a.profile(tx, owner)
	if err != nil {
		accountError(w, err)
		return
	}
	reply(w, 200, profile)
}
func (app *application) logout(w http.ResponseWriter, r *http.Request) {
	hash := tokenDigest(app.token(r))
	if _, err := app.accounts.db.ExecContext(r.Context(), "DELETE FROM sessions WHERE digest=?", hash); err != nil {
		reply(w, 503, nil)
		return
	}
	if r.Header.Get("X-Birka-Client") == "web" {
		app.cookie(w, "", -1)
	}
	reply(w, 204, nil)
}
