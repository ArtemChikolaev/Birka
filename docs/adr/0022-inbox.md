# ADR 0022 — The inbox

**Status:** accepted 2026-11-04.

## Context

- An import puts the operations whose category of the bank nobody chose
  into the ledger without a category ([ADR 0021](0021-statements.md), point
  12). They count in the balances and the reports, but someone has to sort
  them, and most of them look like operations the person sorted before.
- A bank exports only its own side of a transfer between one's own
  accounts: the statement of a card shows a top-up from a card abroad as an
  income, and the statement of that card shows it as an expense. As income
  and spending they make the capital look bigger and the month look
  costlier than they were.
- The mockups show the inbox on the site: the transfers to link, with the
  rate against that of the Bank of Russia, and the operations without a
  category, each with a hint from past choices, a «Да» and another
  category, several picked at once.
- Nothing about the person leaves the device, so the inbox can only learn
  from what the ledger already holds.

## Decision

1. The inbox lives in `packages/features/inbox`. `inbox_common` holds the
   state and both hosts draw it. It reads the whole ledger and the rates,
   and counts again on every change of them.
2. An operation waits in the inbox while one of its allocations has no
   category. It leaves once it has one; the inbox writes nothing of its own
   about it.
3. `CategoryMemory` in `ledger` suggests a category from the expenses and
   income of one category that the person has, in this order:
   - the same name: the note in lower case without digits, so that
     «Пятёрочка 1234» meets «ПЯТЕРОЧКА 77»; the category given most, the
     latest of a tie, with how many times and since when;
   - the same amount on the same account in at least two of the three
     months before;
   - a similar name: a word of four letters or more in common, or one the
     start of the other from five letters, compared in Latin letters so that
     `BARBERSHOP 77` meets «Барбершоп»; first in the same import, else the
     latest. Words that banks put everywhere, such as «перевод» or `CARD`,
     do not count.
   A hint names its category only while that is open and of the kind of the
   operation. It sits in `ledger` because the import can use it too.
4. A choice amends the operation with the category in its allocations
   without one. It keeps its import, so the undo of the import still takes
   it out. Several picked operations get one category in one write; those of
   the other kind stay picked.
5. A transfer to link is an income without a category on one account and an
   expense on another within three days of it: of the same amount in one
   currency, or within 10% of the rate of the Bank of Russia on the day the
   money left between two currencies ([ADR 0012](0012-exchange-rates.md)).
   Each operation is in one pair at most, the closest first, and both of a
   pair wait in its card rather than in the list.
6. «Сделать переводом» puts one transfer in place of the two operations in
   one write: from the account of the expense to that of the income, on the
   day of the expense, with both amounts and both notes. It is the person's
   own record and belongs to no import, as what the person recorded stays
   after the undo of an import ([ADR 0021](0021-statements.md), point 11).
7. «Это доход» keeps the pair apart on this device, by the ids of its two
   operations in the settings ([ADR 0011](0011-settings.md)), and its income
   waits for a category as any other.
8. The phone shows the same inbox in a page of its own (`inbox_flutter`),
   as its board draws it: the pairs above, then the operations, each with a
   box that picks it, its hint with «Да» and a sheet of any category, the
   hinted one marked; the picked get one category from a bar at the
   bottom. A word after each choice says what was done. The result of an
   import on the phone leads to it, and with nothing to sort it offers a
   statement. The sheet of categories ends with «Новая категория»: the
   form of a category opens over the inbox, and the category it saves
   goes to the operations at once, those of its kind only.

## Options considered

| Option | Why not |
|---|---|
| A table of the inbox in the database | the state follows from the categories and the transactions; a second truth would drift from them, and a copy of the ledger would carry it |
| A model of language for the hints | the operations would leave the device, or a model would have to live in it; past choices already name most places |
| Turning the income into a transfer and deleting only the expense | the transfer would belong to the import of the income, and its undo would take the money of the other side out with it |
| Linking transfers while importing | the other side is often in another file, read weeks later, or typed in by hand |

## Consequences

- The inbox costs nothing to keep: it is the ledger as it stands, and a copy
  of the ledger restores it, but for the pairs kept apart.
- A transfer that the person links cannot be split again; deleting it and
  typing the two sides in is the way back.
- The hints learn from every choice: a «Да» adds an operation of that name
  to the memory, and the next import gives such operations their category
  at once ([ADR 0021](0021-statements.md), point 17).
- The site draws the inbox (`inbox_jaspr`) as the mockup does, and the
  phone as its own board does (`inbox_flutter`); on both the result of an
  import leads to it. A lasting way to it, from More or the overview, is
  not drawn yet.
