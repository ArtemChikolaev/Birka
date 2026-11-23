# Import the same statement twice

Restore the synthetic category-limit ledger. Test card starts at ₽9,850
after one expense. The synthetic Alfa-format CSV in
`tools/fixtures/statement-reimport.csv` has a ₽250 expense and ₽1,000 refund.

1. Choose the CSV in Import, confirm its columns and select Test card.
2. Import both operations. On the account page verify three rows and ₽10,600.
3. Choose the same file and account again. Duplicates identifies both rows.
   With the default decision to skip them, **Nothing to add** is disabled.
4. Reopen Test card and reload. It must still show the original expense and
   each imported amount exactly once, with the same ₽10,600 balance.

## Sources and callers

[ADR 0021](../../../../docs/adr/0021-statements.md) defines the import decisions.
The [shared import plan](../../../../packages/features/import/common/lib/src/domain/import_plan.dart)
matches existing operations and applies the skip or keep choices used in the
[Flutter import sheet](../../../../packages/features/import/flutter/lib/src/presentation/import_sheet.dart)
and the
[Jaspr import wizard](../../../../packages/features/import/jaspr/lib/src/presentation/pages/import_page.dart).
