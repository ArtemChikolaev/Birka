package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/mail"
	"net/textproto"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
	"time"
)

func testStore(t *testing.T) *accounts {
	t.Helper()
	a, err := openAccounts(filepath.Join(t.TempDir(), "accounts.db"), make([]byte, 32))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { a.db.Close() })
	return a
}

// A local SMTP receiver records the same MIME message a mail client would read.
func mailbox(t *testing.T) (string, <-chan string) {
	t.Helper()
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { listener.Close() })
	messages := make(chan string, 4)
	go func() {
		for {
			c, err := listener.Accept()
			if err != nil {
				return
			}
			func() {
				defer c.Close()
				c.SetDeadline(time.Now().Add(5 * time.Second))
				p := textproto.NewConn(c)
				p.PrintfLine("220 local.test ESMTP")
				for {
					cmd, err := p.ReadLine()
					if err != nil {
						return
					}
					switch strings.Fields(cmd)[0] {
					case "EHLO", "HELO", "MAIL", "RCPT":
						p.PrintfLine("250 OK")
					case "DATA":
						p.PrintfLine("354 Continue")
						msg, err := p.ReadDotBytes()
						if err != nil {
							return
						}
						messages <- string(msg)
						p.PrintfLine("250 Queued")
					case "QUIT":
						p.PrintfLine("221 Bye")
						return
					default:
						p.PrintfLine("500 Unexpected command")
					}
				}
			}()
		}
	}()
	return listener.Addr().String(), messages
}

func TestRegistrationAndReturningDevice(t *testing.T) {
	a := testStore(t)
	smtpAddress, messages := mailbox(t)
	m := mailer{address: smtpAddress, from: "sender@example.test", local: true}
	const origin = "https://site.example.test"
	app := application{accounts: a, send: m.send, origin: origin}
	handler := app.handler()
	send := func(mode, path string, body map[string]string, cookie *http.Cookie, token string, want int) (*http.Cookie, map[string]string) {
		t.Helper()
		b, err := json.Marshal(body)
		if err != nil {
			t.Fatal(err)
		}
		method := "POST"
		if path == "session" {
			method = "GET"
		}
		r := httptest.NewRequest(method, "/v1/"+path, bytes.NewReader(b))
		r.Header.Set("X-Birka-Client", mode)
		r.Header.Set("Content-Type", "application/json")
		if mode == "web" {
			r.Header.Set("Origin", origin)
		}
		if cookie != nil {
			r.AddCookie(cookie)
		}
		if token != "" {
			r.Header.Set("Authorization", "Bearer "+token)
		}
		w := httptest.NewRecorder()
		handler.ServeHTTP(w, r)
		if w.Code != want {
			t.Fatalf("%s %s: got %d, want %d", mode, path, w.Code, want)
		}
		if w.Header().Get("Cache-Control") != "no-store" {
			t.Fatal("private response is cacheable")
		}
		var data map[string]string
		if w.Body.Len() > 0 && json.Unmarshal(w.Body.Bytes(), &data) != nil {
			t.Fatal("invalid response")
		}
		var out *http.Cookie
		if cc := w.Result().Cookies(); len(cc) > 0 {
			out = cc[0]
		}
		return out, data
	}
	address := "returning@example.test"
	start := func(mode, language string) map[string]string {
		t.Helper()
		_, issued := send(mode, "code", map[string]string{"email": " Returning@Example.Test ", "language": language}, nil, "", 200)
		raw := <-messages
		msg, err := mail.ReadMessage(strings.NewReader(raw))
		if err != nil {
			t.Fatal(err)
		}
		body, err := io.ReadAll(base64.NewDecoder(base64.StdEncoding, msg.Body))
		if err != nil {
			t.Fatal(err)
		}
		if msg.Header.Get("To") != address || !strings.Contains(string(body), "Birka") {
			t.Fatal("unexpected mail")
		}
		code := regexp.MustCompile(`\b[0-9]{6}\b`).FindString(string(body))
		if code == "" || len(issued) != 1 {
			t.Fatal("code was not delivered exclusively by email")
		}
		return map[string]string{"challenge": issued["challenge"], "code": code}
	}
	verify := start("web", "ru")
	var count int
	if err := a.db.QueryRow("SELECT count(*) FROM accounts").Scan(&count); err != nil || count != 0 {
		t.Fatal("account created before verification")
	}
	cookie, profile := send("web", "verify", verify, nil, "", 200)
	if profile["email"] != address || len(profile) != 1 || cookie == nil || !cookie.HttpOnly || !cookie.Secure || cookie.Name != "__Host-birka_session" || cookie.SameSite != http.SameSiteLaxMode || cookie.Domain != "" || cookie.Path != "/" {
		t.Fatal("invalid browser session")
	}
	send("web", "verify", verify, nil, "", 401)
	send("web", "session", nil, cookie, "", 200)
	_, native := send("native", "verify", start("native", "en"), nil, "", 200)
	if native["email"] != address || native["token"] == "" {
		t.Fatal("invalid native session")
	}
	if err := a.db.QueryRow("SELECT count(*) FROM accounts").Scan(&count); err != nil || count != 1 {
		t.Fatal("returning device created another account")
	}
	send("web", "logout", nil, cookie, "", 204)
	send("web", "session", nil, cookie, "", 401)
	send("native", "session", nil, nil, native["token"], 200)
	a.now = func() time.Time { return time.Now().Add(sessionAge + time.Second) }
	send("native", "session", nil, nil, native["token"], 401)
}

func TestCodeLifetimeAttemptsAndConcurrentUse(t *testing.T) {
	a := testStore(t)
	now := time.Now()
	a.now = func() time.Time { return now }
	ctx := context.Background()
	issue := func() (string, string) {
		t.Helper()
		id, code, err := a.issue(ctx, "a@example.test", "localhost")
		if err != nil {
			t.Fatal(err)
		}
		return id, code
	}
	reject := func(id, code string) {
		t.Helper()
		_, _, err := a.verify(ctx, id, code)
		if !errors.Is(err, errCode) {
			t.Fatalf("expected rejected code, got %v", err)
		}
	}
	id, code := issue()
	if _, _, err := a.issue(ctx, "a@example.test", "localhost"); !errors.Is(err, errLimit) {
		t.Fatal("missing cooldown")
	}
	now = now.Add(time.Minute)
	next, digits := issue()
	reject(id, code)
	wrong := "123456"
	if wrong == digits {
		wrong = "234567"
	}
	for range 5 {
		reject(next, wrong)
	}
	reject(next, digits)
	now = now.Add(time.Minute)
	id, code = issue()
	now = now.Add(codeAge)
	reject(id, code)
	id, code = issue()
	done := make(chan error, 2)
	for range 2 {
		go func() { _, _, err := a.verify(ctx, id, code); done <- err }()
	}
	first, second := <-done, <-done
	if !(first == nil && errors.Is(second, errCode) || second == nil && errors.Is(first, errCode)) {
		t.Fatal("concurrent verification must succeed exactly once")
	}
}

func TestQuotasAndCleanup(t *testing.T) {
	a := testStore(t)
	now := time.Now()
	a.now = func() time.Time { return now }
	ctx := context.Background()
	for i := range 30 {
		_, _, err := a.issue(ctx, fmt.Sprintf("e%d@example.test", i), "ip")
		if err != nil {
			t.Fatal(err)
		}
	}
	if _, _, err := a.issue(ctx, "another@example.test", "ip"); !errors.Is(err, errLimit) {
		t.Fatal("IP quota")
	}
	for i := range 5 {
		now = now.Add(time.Minute)
		_, _, err := a.issue(ctx, "same@example.test", fmt.Sprint(i))
		if err != nil {
			t.Fatal(err)
		}
	}
	now = now.Add(time.Minute)
	if _, _, err := a.issue(ctx, "same@example.test", "else"); !errors.Is(err, errLimit) {
		t.Fatal("address quota")
	}
	now = now.Add(time.Hour)
	if err := a.cleanup(); err != nil {
		t.Fatal(err)
	}
	if _, _, err := a.issue(ctx, "same@example.test", "ip"); err != nil {
		t.Fatal(err)
	}
}

func TestRequestBoundaries(t *testing.T) {
	app := application{accounts: testStore(t), origin: "https://site.example.test", send: func(_, _, _ string) error { return errors.New("mail is down") }}
	for _, test := range []struct {
		origin, mode, body string
		status             int
	}{
		{"https://other.example.test", "web", "{}", 403},
		{app.origin, "native", "{}", 403},
		{"", "", "{}", 403},
		{app.origin, "web", `{"email":"invalid"}`, 400},
		{app.origin, "web", strings.Repeat(" ", 4096) + "{}", 400},
		{app.origin, "web", `{"email":"a@example.test"}`, 503},
	} {
		r := httptest.NewRequest("POST", "/v1/code", strings.NewReader(test.body))
		r.Header.Set("Origin", test.origin)
		r.Header.Set("X-Birka-Client", test.mode)
		r.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		app.handler().ServeHTTP(w, r)
		if w.Code != test.status {
			t.Errorf("status %d, want %d", w.Code, test.status)
		}
	}
	var n int
	if err := app.accounts.db.QueryRow("SELECT count(*) FROM challenges").Scan(&n); err != nil || n != 0 {
		t.Fatal("undeliverable code is usable")
	}
}

func TestStoreProtectsAccountMaterial(t *testing.T) {
	a := testStore(t)
	ctx := context.Background()
	const email = "fixture@example.test"
	const ip = "192.0.2.14"
	id, code, err := a.issue(ctx, email, ip)
	if err != nil {
		t.Fatal(err)
	}
	var lookup string
	var address, proof []byte
	if err = a.db.QueryRow("SELECT email,address,digest FROM challenges").Scan(&lookup, &address, &proof); err != nil {
		t.Fatal(err)
	}
	if lookup == email || bytes.Contains(address, []byte(email)) || string(proof) == code {
		t.Fatal("plaintext challenge record")
	}
	var n int
	if err = a.db.QueryRow("SELECT count(*) FROM quotas WHERE source IN (?,?)", email, ip).Scan(&n); err != nil || n != 0 {
		t.Fatal("plaintext quota identifier")
	}
	_, token, err := a.verify(ctx, id, code)
	if err != nil {
		t.Fatal(err)
	}
	if err = a.db.QueryRow("SELECT digest FROM sessions").Scan(&proof); err != nil || len(proof) != 32 || string(proof) == token {
		t.Fatal("unprotected session")
	}
}
