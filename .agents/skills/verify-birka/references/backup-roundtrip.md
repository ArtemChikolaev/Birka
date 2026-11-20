# Move a ledger to another browser

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
