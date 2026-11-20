# Monthly category limits on the site

## Starting state

The verifier opens the built site in a fresh Chrome profile on November 18,
2026, in English. The Data screen restores the synthetic Birka copy from
`tools/fixtures/category-limit.json`. Its only account is in rubles. Cafe
has a monthly limit of ₽12,000 and one expense of ₽10,150.

## User journey

| Action | Expected visible result |
| --- | --- |
| Follow All limits from Overview | The Cafe row shows ₽1,850 left |
| Open a new operation and enter 1850 for Cafe | Quick add previews ₽0 of ₽12,000 left |
| Save the expense and open Limits | The Cafe row shows ₽0 left |
| Add and save one more ruble | The preview and then the Cafe row show ₽1 over the limit |
| Reload Limits | The new document shows the same ₽1 overage |

## What proves the change

The amounts before saving come from quick add. The later amounts come from the
limits page reading the browser ledger. The check waits for the new document
after reload. Run it against a fresh build of the change under review.
The threshold and accounting rules are in ADR 0033. This journey covers the
Jaspr host, one currency and manually entered spending.
