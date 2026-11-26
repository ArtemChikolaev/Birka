package main

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

type gatewayTransport func(*http.Request) (*http.Response, error)

func (f gatewayTransport) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func gatewayResponse(status int, body string) *http.Response {
	return &http.Response{StatusCode: status, Header: make(http.Header), Body: io.NopCloser(strings.NewReader(body))}
}

func TestGatewayResponse(t *testing.T) {
	for _, tc := range []struct {
		name   string
		status int
		body   string
		want   error
	}{
		{"accepted", 200, `{"ok":true,"result":{"request_id":"local-id"}}`, nil},
		{"rejected", 200, `{"ok":false,"error":"private detail"}`, errDelivery},
		{"missing receipt", 200, `{"ok":true,"result":{}}`, errDelivery},
		{"invalid response", 200, "not JSON", errDelivery},
		{"rate limited", 429, "", errLimit},
		{"unavailable", 503, "", errDelivery},
		{"redirect", 307, "", errDelivery},
		{"network failure", 0, "", errDelivery},
	} {
		t.Run(tc.name, func(t *testing.T) {
			calls := 0
			send := telegramSender("local-token", gatewayTransport(func(r *http.Request) (*http.Response, error) {
				calls++
				if r.Method != "POST" || r.URL.String() != "https://gatewayapi.telegram.org/sendVerificationMessage" || r.Header.Get("Authorization") != "Bearer local-token" || r.Header.Get("Content-Type") != "application/json" {
					t.Fatal("unexpected Gateway request")
				}
				var payload map[string]any
				if err := json.NewDecoder(r.Body).Decode(&payload); err != nil || len(payload) != 3 || payload["phone_number"] != "+12025550123" || payload["code"] != "001234" || payload["ttl"] != float64(600) {
					t.Fatal("invalid Gateway payload")
				}
				if tc.status == 0 {
					return nil, errors.New("private transport error")
				}
				res := gatewayResponse(tc.status, tc.body)
				if tc.status == 307 {
					res.Header.Set("Location", "https://example.test/redirect")
				}
				return res, nil
			}))
			if err := send(t.Context(), "+12025550123", "001234"); !errors.Is(err, tc.want) || calls != 1 {
				t.Fatalf("delivery result %v, calls %d", err, calls)
			}
		})
	}
}

func TestTelegramAccountLifecycle(t *testing.T) {
	a := testStore(t)
	now := time.Now()
	a.now = func() time.Time { return now }
	var phone, code string
	sent := 0
	app := application{accounts: a, telegramLimit: 12, send: func(_, c, _ string) error { code = c; return nil }}
	app.telegram = telegramSender("test", gatewayTransport(func(r *http.Request) (*http.Response, error) {
		var payload struct {
			Phone string `json:"phone_number"`
			Code  string
		}
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			t.Fatal(err)
		}
		phone, code = payload.Phone, payload.Code
		sent++
		return gatewayResponse(200, `{"ok":true,"result":{"request_id":"test"}}`), nil
	}))
	handler := app.handler()
	post := func(path string, body map[string]any, token string, status int) map[string]string {
		t.Helper()
		raw, err := json.Marshal(body)
		if err != nil {
			t.Fatal(err)
		}
		r := httptest.NewRequest("POST", "/v1/"+path, bytes.NewReader(raw))
		r.Header.Set("Content-Type", "application/json")
		r.Header.Set("X-Birka-Client", "native")
		if token != "" {
			r.Header.Set("Authorization", "Bearer "+token)
		}
		w := httptest.NewRecorder()
		handler.ServeHTTP(w, r)
		if w.Code != status {
			t.Fatalf("%s returned %d, want %d", path, w.Code, status)
		}
		var out map[string]string
		if w.Body.Len() > 0 && json.NewDecoder(w.Body).Decode(&out) != nil {
			t.Fatal("invalid response")
		}
		return out
	}
	const number = "+12025550123"
	phoneReq := map[string]any{"phone": "+1 (202) 555-0123", "consent": true}
	post("code", map[string]any{"phone": number}, "", 400)
	post("code", map[string]any{"phone": "invalid", "consent": true}, "", 400)
	post("code", map[string]any{"phone": number, "consent": true, "link": true}, "", 401)
	if sent != 0 {
		t.Fatal("unexpected send")
	}
	challenge := func(body map[string]any, token string) map[string]any {
		t.Helper()
		issued := post("code", body, token, 200)
		if len(issued) != 1 || len(issued["challenge"]) != 43 || !digits.MatchString(code) {
			t.Fatal("invalid challenge or delivered code")
		}
		return map[string]any{"challenge": issued["challenge"], "code": code}
	}
	count := func(table string, want int) {
		t.Helper()
		var got int
		if err := a.db.QueryRow("SELECT count(*) FROM " + table).Scan(&got); err != nil || got != want {
			t.Fatalf("unexpected count for %s: %d", table, got)
		}
	}
	verify := challenge(phoneReq, "")
	if phone != number {
		t.Fatal("noncanonical phone")
	}
	proof := post("verify", verify, "", 200)
	if len(proof) != 1 || proof["registration"] == "" {
		t.Fatal("missing registration confirmation")
	}
	count("accounts", 0)
	count("sessions", 0)
	post("verify", verify, "", 401)
	post("code", phoneReq, "", 429)
	create := map[string]any{"registration": proof["registration"]}
	first := post("register", create, "", 200)
	token := first["token"]
	if token == "" || first["telegram"] != "•••• 0123" {
		t.Fatal("invalid Telegram profile")
	}
	post("register", create, "", 401)
	const email = "linked@example.test"
	link := challenge(map[string]any{"email": email, "link": true}, token)
	post("verify", link, "", 401)
	linked := post("verify", link, token, 200)
	if len(linked) != 2 || linked["email"] != email || linked["telegram"] != first["telegram"] {
		t.Fatal("link must preserve the session and return both methods")
	}
	now = now.Add(time.Minute)
	returning := post("verify", challenge(phoneReq, ""), "", 200)
	if returning["email"] != email || returning["token"] == token {
		t.Fatal("returning phone did not resume the linked identity")
	}
	same := post("verify", challenge(map[string]any{"email": email}, ""), "", 200)
	if same["telegram"] != first["telegram"] {
		t.Fatal("email did not reach same profile")
	}
	count("accounts", 1)
	other := post("verify", challenge(map[string]any{"email": "other@example.test"}, ""), "", 200)
	now = now.Add(time.Minute)
	phoneReq["link"] = true
	conflict := challenge(phoneReq, other["token"])
	post("verify", conflict, token, 401)
	post("verify", conflict, other["token"], 409)
	post("verify", conflict, other["token"], 401)
	count("methods", 3)
	phoneReq["phone"] = "+12025550124"
	next := challenge(phoneReq, other["token"])
	linked = post("verify", next, other["token"], 200)
	if linked["email"] != other["email"] || linked["telegram"] != "•••• 0124" {
		t.Fatal("phone linking failed")
	}
	var address []byte
	if err := a.db.QueryRow("SELECT address FROM methods WHERE lookup=?", a.lookup(telegramChannel, number)).Scan(&address); err != nil || bytes.Contains(address, []byte(number)) {
		t.Fatal("phone not protected")
	}
}

func TestGatewayFailureAndBudget(t *testing.T) {
	a := testStore(t)
	now := time.Now()
	a.now = func() time.Time { return now }
	called := 0
	app := application{accounts: a, telegramLimit: 1}
	call := func(path string, body string, status int) string {
		t.Helper()
		method := "POST"
		if path == "methods" {
			method = "GET"
		}
		r := httptest.NewRequest(method, "/v1/"+path, strings.NewReader(body))
		r.Header.Set("Content-Type", "application/json")
		r.Header.Set("X-Birka-Client", "web")
		w := httptest.NewRecorder()
		app.handler().ServeHTTP(w, r)
		if w.Code != status {
			t.Fatalf("%s returned %d, want %d", path, w.Code, status)
		}
		return w.Body.String()
	}
	const first = `{"phone":"+12025550123","consent":true}`
	call("code", first, 503)
	if !strings.Contains(call("methods", "", 200), `"telegram":false`) {
		t.Fatal("disabled provider advertised")
	}
	app.telegram = func(context.Context, string, string) error { called++; return errDelivery }
	if !strings.Contains(call("methods", "", 200), `"telegram":true`) {
		t.Fatal("enabled provider missing")
	}
	call("code", first, 502)
	call("code", first, 429)
	now = now.Add(time.Minute)
	call("code", `{"phone":"+12025550124","consent":true}`, 429)
	var n int
	if err := a.db.QueryRow("SELECT count(*) FROM challenges").Scan(&n); err != nil || n != 0 || called != 1 {
		t.Fatal("failed delivery retained a challenge or exceeded the budget")
	}
	now = now.Add(time.Hour)
	call("code", first, 502)
}

func TestLegacyEmailMigration(t *testing.T) {
	const email = "legacy@example.test"
	path := filepath.Join(t.TempDir(), "legacy.db")
	old, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	keys := testStore(t)
	lookup := keys.lookup(emailChannel, email)
	address := keys.addresses.Seal(nil, nil, []byte(email), []byte(lookup))
	id := randomToken()
	token := randomToken()
	_, err = old.Exec(`CREATE TABLE accounts(email TEXT PRIMARY KEY,address BLOB NOT NULL);
 CREATE TABLE sessions(digest BLOB PRIMARY KEY,email TEXT NOT NULL REFERENCES accounts(email),expires INTEGER NOT NULL);
 CREATE INDEX session_expiry ON sessions(expires);
 CREATE TABLE challenges(email TEXT PRIMARY KEY,address BLOB NOT NULL,id TEXT UNIQUE NOT NULL,digest BLOB NOT NULL,issued INTEGER NOT NULL,attempts INTEGER NOT NULL DEFAULT 0);
 CREATE TABLE quotas(kind TEXT NOT NULL,source TEXT NOT NULL,started INTEGER NOT NULL,used INTEGER NOT NULL,PRIMARY KEY(kind,source));`)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = old.Exec("INSERT INTO accounts VALUES(?,?)", lookup, address); err != nil {
		t.Fatal(err)
	}
	if _, err = old.Exec("INSERT INTO sessions VALUES(?,?,?)", tokenDigest(token), lookup, time.Now().Add(sessionAge).Unix()); err != nil {
		t.Fatal(err)
	}
	if _, err = old.Exec("INSERT INTO challenges VALUES(?,?,?,?,?,4)", lookup, address, id, keys.digestCode(id, "000123"), time.Now().Unix()); err != nil {
		t.Fatal(err)
	}
	if err = old.Close(); err != nil {
		t.Fatal(err)
	}
	for i := range 2 {
		db, err := openAccounts(path, make([]byte, 32))
		if err != nil {
			t.Fatal(err)
		}
		tx, err := db.db.Begin()
		if err != nil {
			t.Fatal(err)
		}
		owner, err := sessionOwner(tx, tokenDigest(token), time.Now().Unix())
		if err != nil {
			t.Fatal(err)
		}
		p, err := db.profile(tx, owner)
		if err != nil || p["email"] != email {
			t.Fatal("lost legacy profile")
		}
		tx.Rollback()
		if i == 0 {
			v, err := db.verify(t.Context(), id, "000123", "")
			if err != nil || v.profile["email"] != email {
				t.Fatal("lost outstanding email challenge")
			}
		}
		if err = db.db.Close(); err != nil {
			t.Fatal(err)
		}
	}
}

func TestRegistrationExpiryReplacementAndSessionRevocation(t *testing.T) {
	a := testStore(t)
	now := time.Now()
	a.now = func() time.Time { return now }
	issue := func(channel, value string, binding []byte) (string, string) {
		t.Helper()
		id, code, err := a.issue(t.Context(), channel, value, "localhost", binding, 60)
		if err != nil {
			t.Fatal(err)
		}
		return id, code
	}
	proof := func() string {
		t.Helper()
		id, code := issue(telegramChannel, "+12025550126", nil)
		v, err := a.verify(t.Context(), id, code, "")
		if err != nil || v.registration == "" {
			t.Fatal("expected a registration proof")
		}
		return v.registration
	}
	obsolete := proof()
	now = now.Add(time.Minute)
	expired := proof()
	if _, err := a.register(t.Context(), obsolete); !errors.Is(err, errCode) {
		t.Fatal("replacement left the old proof usable")
	}
	now = now.Add(codeAge)
	if _, err := a.register(t.Context(), expired); !errors.Is(err, errCode) {
		t.Fatal("expired proof created an account")
	}
	id, code := issue(emailChannel, "bound@example.test", nil)
	v, err := a.verify(t.Context(), id, code, "")
	if err != nil {
		t.Fatal(err)
	}
	id, code = issue(telegramChannel, "+12025550126", tokenDigest(v.token))
	if _, err = a.db.Exec("DELETE FROM sessions WHERE digest=?", tokenDigest(v.token)); err != nil {
		t.Fatal(err)
	}
	if _, err = a.verify(t.Context(), id, code, v.token); !errors.Is(err, errSession) {
		t.Fatal("revoked session linked a phone")
	}
	var count int
	if err = a.db.QueryRow("SELECT count(*) FROM methods WHERE channel='telegram'").Scan(&count); err != nil || count != 0 {
		t.Fatal("a phone was linked")
	}
}
