# 0035. Optional account access by email code

Accepted 2026-11-26.

## Decision

Both hosts open **More → Birka account** on demand. Registration and returning
sign-in use the same form. Confirming the first code creates the identity.
Starting Birka, onboarding, tracking money and opening a backup work offline.
Signing in and signing out never write to the ledger. The profile shows counts
read from this device and explains how to move records with an existing backup.
The [mockup](../design/mockups/optional-account.html) covers both hosts.

The shared Dart feature owns validation, request state and the HTTP contract.
An absent service URL leaves a guest exit on the account page. The web host
uses an HttpOnly, host-only, Secure, SameSite=Lax cookie. The server checks
the exact browser origin and requires a non-simple client header. The native
host keeps its opaque session credential in platform secure storage, scoped
to the service URL. Each device gets a separate 30-day session. Signing out
revokes that session.

The Go service under `server/auth` delivers six digits by SMTP. Challenges
last ten minutes and allow five guesses. A new challenge replaces the previous
one after a one-minute cooldown. An address can receive five messages and an
IP can request thirty in an hour. The service creates the account and session
and consumes the challenge in a single SQLite transaction.

Only the email identity goes to the service. The database stores addresses
encrypted with AES-GCM, keyed lookups for email and IP quotas, keyed code
digests, and SHA-256 session digests. Expired challenges, quotas and sessions
are removed regularly. The operator keeps the service key separate from the
database. Neither local record counts nor backup files enter this protocol.

[Running the service and testing local delivery](../../server/README.md)
