# Birka account service

The Go service handles optional email-code registration and sign-in for the
Flutter app and static site. It needs Go 1.25 or later, a writable private
directory, and an SMTP relay. `make test-auth` runs the service tests and
delivers a real MIME message to a temporary loopback SMTP receiver.

## Local mail

Start a local SMTP inbox such as [Mailpit](https://mailpit.axllent.org/docs/).
With the Mailpit executable on your path, use one terminal for the inbox.

```sh
mailpit --listen 127.0.0.1:8025 --smtp 127.0.0.1:1025
```

In a second terminal, run the service from the repository root. The following
commands keep the database and the generated key outside the checkout. Use the
same private directory and key across restarts.

```sh
umask 077
export BIRKA_ACCOUNT_DIR="${TMPDIR:-/tmp}/birka-local-account"
mkdir -p "$BIRKA_ACCOUNT_DIR"
test -f "$BIRKA_ACCOUNT_DIR/key" || openssl rand -base64 32 > "$BIRKA_ACCOUNT_DIR/key"
export BIRKA_AUTH_KEY="$(cat "$BIRKA_ACCOUNT_DIR/key")"
export BIRKA_AUTH_DB="$BIRKA_ACCOUNT_DIR/accounts.db"
export BIRKA_AUTH_LOCAL=1
export BIRKA_AUTH_LISTEN=127.0.0.1:8787
export BIRKA_WEB_ORIGIN=http://localhost:8080
export BIRKA_SMTP_ADDR=127.0.0.1:1025
export BIRKA_MAIL_FROM=birka@example.test
cd server && go run ./auth
```

From the repository root, launch either host in another terminal.

```sh
make run-web BIRKA_AUTH_URL=http://localhost:8787
# Or run the Flutter development host
make run-mobile DEVICE=macos BIRKA_AUTH_URL=http://localhost:8787
```

Open the site at `http://localhost:8080`. In **More → Birka account**, enter a
synthetic address such as `reader@example.test`. Read its six digits in the
local inbox at `http://127.0.0.1:8025`, verify, reload the page and sign out.
A fresh browser profile can sign into the same account with a new email. Its
financial records come from that profile's ledger. Local mode restricts both
the SMTP receiver and the HTTP listener to loopback.

## Published builds

Set the public `BIRKA_AUTH_URL` repository variable for the web and Android
workflows once a service and sender are available. Leave it unset for a
guest-only build. iOS accepts the same Flutter `--dart-define`.
Serve the API and site under the same HTTPS site, for example
`app.example.com` and `auth.example.com`. A Pages site needs a compatible
custom domain or a same-origin reverse proxy for browser cookies.

Run the service with `BIRKA_AUTH_LOCAL` unset, a private database directory,
a stable secret `BIRKA_AUTH_KEY`, the exact `BIRKA_WEB_ORIGIN` (origin only),
and a verified `BIRKA_MAIL_FROM`. Configure `BIRKA_SMTP_ADDR` for STARTTLS
and `BIRKA_SMTP_USER` and `BIRKA_SMTP_PASSWORD` when the relay authenticates.
Back up the database and secret separately. Losing the secret makes stored
addresses unreadable. Terminate HTTPS at a reverse proxy on the service host.
Configure the proxy to overwrite `X-Real-IP` with the client address and set
`BIRKA_TRUST_LOCAL_PROXY=1` to apply the IP quota per client. Keep request
bodies, credentials, cookies and email codes out of proxy and relay logs.
