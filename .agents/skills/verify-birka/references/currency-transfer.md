# Transfer between two currencies

Restore `tools/fixtures/currency-transfer.json` in a fresh browser profile.
Ruble card starts at ₽10,000 and Dollar card at $20. Both histories are empty.

1. In Operations, start a transfer from Ruble card to Dollar card.
2. Enter ₽1,234.56 under Leaves and $12.34 under Arrives. Read both previews
   and save the transfer. Both amounts are entered on the keypad.
3. Open and reload each account. Ruble card shows ₽8,765.44 and one debit
   of −₽1,234.56. Dollar card shows $32.34 and one credit of +$12.34.
4. Open the credit. The operation is a transfer and shows ₽1,234.56 → $12.34.

Run `make verify-web FLOW=currency-transfer BASE=/Birka/` after building the
site with that base. The report contains the values read on each page.
