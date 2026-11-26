# 0036. Optional sign-in through Telegram Gateway

Accepted 2026-11-26.

## Decision

Flutter and Jaspr discover the server's configured email and Telegram methods through `GET /v1/methods`. Guest use and the local ledger follow [ADR 0035](0035-optional-account.md). Both hosts follow the [approved design](../design/mockups/optional-account.html#telegram).

Before requesting a Telegram code, the user enters an international phone number and gives permission to share that number for delivery. Editing the number clears consent. Birka sends its own six-digit code and ten-minute TTL through the Gateway's authenticated HTTPS API. The service holds the access token and checks the code locally. It limits attempts per number, per IP and across all Telegram requests. It sends once per user request.

Verifying a known number starts a device session. Verifying an unknown number returns a single-use registration proof, valid until the original challenge expires. Only explicit confirmation creates the account. A person with an existing email account may instead sign in by email and link the number from their profile. The reverse path adds email to a phone-based account. Linking requires both the live session that requested the code and proof of the new method. Each verified identifier belongs to one account and each account can hold one of each kind.

The database migrates existing email accounts, challenges, quotas and sessions on startup. Lookups are keyed by channel and contacts are encrypted with AES-GCM. Phone numbers leave the service in masked form on profile responses. Codes, session credentials and registration proofs are stored as digests.

[Server configuration and local tests](../../server/README.md#telegram-gateway)
