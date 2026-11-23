# Import the same statement twice

## Web

Restore the synthetic category-limit ledger. Test card starts at ₽9,850
after one expense. The synthetic Alfa-format CSV in
`tools/fixtures/statement-reimport.csv` has a ₽250 expense and ₽1,000 refund.

1. Choose the CSV in Import, confirm its columns and select Test card.
2. Import both operations. On the account page verify three rows and ₽10,600.
3. Choose the same file and account again. Duplicates identifies both rows.
   With the default decision to skip them, **Nothing to add** is disabled.
4. Reopen Test card and reload. It must still show the original expense and
   each imported amount exactly once, with the same ₽10,600 balance.

## Flutter on macOS

Run `make verify-flutter FLOW=statement-reimport`. The test opens a separate
SQLite ledger with the same starting amounts. Make passes the web fixture to
this test build, which writes it to a temporary file. The test supplies the
path chosen in the macOS panel. The registered file picker reads the CSV
each time.

1. Open Test card and check its starting balance and original expense.
2. In More → Import, check the detected Alfa-Bank format, select Test card
   and import both operations. Check the three signed entries and ₽10,600.
3. Reopen SQLite and choose the same CSV again. The import sheet shows Test
   card, **2, skipped** and a disabled **Nothing to add** button.
4. Cancel, reopen SQLite again and read all three entries and the unchanged
   balance. CI saves the observations in `flutter-statement-reimport`.

## Sources and callers

[ADR 0021](../../../../docs/adr/0021-statements.md) defines the import decisions.
The [shared import plan](../../../../packages/features/import/common/lib/src/domain/import_plan.dart)
matches existing operations and applies the skip or keep choices used in the
[Flutter import sheet](../../../../packages/features/import/flutter/lib/src/presentation/import_sheet.dart)
and the
[Jaspr import wizard](../../../../packages/features/import/jaspr/lib/src/presentation/pages/import_page.dart).
