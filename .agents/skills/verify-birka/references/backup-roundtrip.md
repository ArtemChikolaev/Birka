# Move a ledger using a saved copy

## Web

Start with the category-limit fixture in a fresh Chrome profile. Test card
opens with ₽20,000, Cafe has a ₽12,000 limit and one expense of ₽10,150.
The harness keeps both profiles in November 2026 so they show that month.

1. Use quick add to spend another ₽150 in Cafe.
2. On Data, save a copy. Wait for Chrome to finish writing the `.birka`
   file to the temporary download folder.
3. In a fresh Chrome profile, restore that downloaded file, confirm the
   replacement and reload. The source browser has already closed.
4. Open Test card. Its balance is ₽9,700 and its two expenses are ₽10,150
   and ₽150. On Limits, Cafe shows ₽1,700 left.

The new expense distinguishes the downloaded copy from the starting fixture.
The verifier removes its temporary downloads when it finishes.

## Flutter on macOS

Run `make verify-flutter FLOW=backup-roundtrip`. The source ledger starts
with the same synthetic amounts in the current month. Enter ₽150 through
quick add, open More → Data and save a copy. The test supplies the paths
normally returned by the macOS panels. The registered file picker writes
and reads the actual `.birka` file.

The source database closes before a separate destination opens. Its only
account is **Destination only**. In Data, choose the saved file and cancel
the replacement. Check that the original account is still there. Choose
the same file again and confirm **Replace the records**. After reopening
the destination database, Test card must show ₽9,700 and both expenses.
On Limits, Cafe must show ₽1,700 remaining.
The destination-only account must be gone. The CI report is
`flutter-backup-roundtrip`.

## Sources and callers

[ADR 0016](../../../../docs/adr/0016-ledger-copy.md) defines replacement and compatibility.
[LedgerCopy](../../../../packages/core/ledger/lib/src/ledger_copy.dart) handles the copy format.
[BackupCubit](../../../../packages/features/backup/common/lib/src/presentation/backup_cubit.dart)
drives the save and restore actions on the
[Flutter Data page](../../../../packages/features/backup/flutter/lib/src/presentation/pages/backup_page.dart)
and the
[Jaspr Data page](../../../../packages/features/backup/jaspr/lib/src/presentation/pages/backup_page.dart).
