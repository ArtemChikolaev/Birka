# Transfer between two currencies

Restore `tools/fixtures/currency-transfer.json` in a fresh browser profile.
Ruble card starts at ₽10,000 and Dollar card at $20. Both histories are empty.

1. In Operations, start a transfer from Ruble card to Dollar card.
2. Enter ₽1,234.56 under Leaves and $12.34 under Arrives. Read both previews
   and save the transfer. Both amounts are entered on the keypad.
3. On Accounts, expand By currency. Rubles shows ₽8,765.44 and Dollars shows
   $32.34.
4. Open and reload each account. Ruble card shows ₽8,765.44 and one debit
   of −₽1,234.56. Dollar card shows $32.34 and one credit of +$12.34.
5. Open the credit. The operation is a transfer and shows ₽1,234.56 → $12.34.

Run `make verify-web FLOW=currency-transfer BASE=/Birka/` after building the
site with that base. The narrow form replaces the list at 390 × 844. At
1440 × 844 the form stands beside the list. Each profile starts from the
same fixture and produces its own report. Pass `WIDTH=390` or `WIDTH=1440`
to reproduce a single layout.

## Flutter

Run `make verify-flutter FLOW=currency-transfer` on macOS or pass a native
device ID as `DEVICE`. The test seeds the same two opening balances in a
temporary SQLite ledger, checks both accounts, then enters both amounts with
the quick-add keypad. It unmounts Birka, closes the ledger and reopens it.
It checks By currency on Accounts, reads both balances and signed rows, then opens the
credit to check the operation type and the amounts. The GitHub workflow
saves these observations and the tested commit in `flutter-currency-transfer`.

## Sources and callers

[ADR 0009](../../../../docs/adr/0009-data-model.md) defines both transfer entries.
[QuickAddCubit.save](../../../../packages/features/transactions/common/lib/src/presentation/quick_add_cubit.dart)
saves the transfer from the amounts entered in
[Flutter quick add](../../../../packages/features/transactions/flutter/lib/src/presentation/pages/quick_add_page.dart)
and
[Jaspr quick add](../../../../packages/features/transactions/jaspr/lib/src/presentation/pages/quick_add_page.dart).
The [Operations host](../../../../apps/web/lib/pages/operations_island.dart) chooses the layout.
