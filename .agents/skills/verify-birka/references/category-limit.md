# Monthly category limits

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
The threshold and accounting rules are in ADR 0033.

## Flutter

Run `make verify-flutter FLOW=category-limit` on macOS, or select a device with
`DEVICE`. The test seeds the same amounts in a temporary SQLite database for
the device's current month, taps through Overview, Limits and quick add, then
unmounts Birka, closes the database and reopens it. The Flutter Limits row
shortens the final label to **₽1 over**. The test deletes its temporary ledger.

To run on a GitHub-hosted Mac, use **Actions → Verify Flutter → Run workflow**
and select a revision, or add the `verify-flutter` label to a PR. Download
`flutter-category-limit` from the run. Its report identifies the tested
commit and records the preview, saved values and the value after reopening.

## Sources and callers

[ADR 0033](../../../../docs/adr/0033-limits.md) sets the thresholds.
[LimitProgress, limitShare and limitStateOf](../../../../packages/core/rates/lib/src/limits.dart)
compute the share and state. Follow the progress into the
[Flutter overview](../../../../packages/features/limits/flutter/lib/src/presentation/widgets/limits_overview_part.dart)
and the shared calculation into the
[Jaspr limit form](../../../../packages/features/limits/jaspr/lib/src/presentation/pages/limit_form_page.dart).
