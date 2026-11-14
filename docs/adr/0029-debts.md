# ADR 0029 — Debts between people

**Status:** accepted 2026-11-14.

## Context

- People lend money to friends and family and borrow from them, often in
  cash and in parts, and forget who owes what by when. Of 210 Russian
  reviews of other trackers that ask for something, 23 ask for debts and
  credits, more than for reports (19).
- A loan is no spending and its return no income: the money only moves
  between the person and someone else. Counted as an expense, a loan would
  swell the month and the report of its category.
- `AccountType.debt` was in the ledger from the start, «money that someone
  owes or is owed», and no screen used it.
- The boards «Долги» of the canvas draw the phone and the site: the row in
  «Ещё», the list with what others owe and what the person owes, the card of
  a person, the form of a new debt, the return, the operations and the
  reminder of the day.

## Decision

1. A debt is an account of type `debt` named after the other person, with
   its terms on the row (version 12 of the schema): who owes whom
   (`DebtSide`: `lent` or `borrowed`), the day it should come back by, and
   whether the phone reminds of that day. Every other account has no terms,
   a debt keeps its type, and an account that a copy or an old database has
   of that type becomes a debt owed to the person.
   The other person later became a record of their own, which the debt
   points at ([ADR 0030](0030-people.md)).
2. A debt never counts towards the capital: the money is not the person's
   now. The ledger keeps `includeInTotals` off on a debt, and the lists and
   pickers of accounts leave debts out unless they ask
   (`watchAccounts(includeDebts: true)`), so that the quick add, the
   accounts, the overview, the regular payments and the imports never see
   them.
3. Money moves on a debt only as transfers between it and an account of the
   person, so a loan and its return stay out of spending, income and every
   report. Its account holds what is owed: above nought while the other one
   owes, below nought while the person does. `DebtMove` names a transfer by
   its side and direction: lent, returned, borrowed and repaid.
4. A debt goes in rounds: a round starts when money goes out while nothing
   is owed and ends when what is owed comes back to nought. Its card says
   what the latest round came to and what came back of it; a settled debt
   moves to «Закрытые» with its day. A person who owes and is owed has two
   debts, one on each side, since each reads one way.
5. A debt is in the currency of the account its first money left or came
   to, and later money moves only between it and accounts in that currency.
   The list adds the debts up in the currency of the totals at the latest
   rates of the CBR and shows a debt in another currency with what it comes
   to.
6. An operation of a debt names the person and what it did, «Маша · в
   долг», says «Долг» and the account of the person below, and shows what it
   did to that account with its sign. It stays among the transfers, and
   quick add does not change it: its card does. Deleting its last
   operation takes a debt out of the lists.
7. A copy of the ledger carries the terms of debts (version 9 of the format,
   [ADR 0016](0016-ledger-copy.md)).
8. `debts_common` holds the debts and their forms for both hosts: the list
   with its totals, the form of a new debt and of more money on one, the
   return of all or of a part, and the terms. The demo has five people:
   Маша owes part of the tickets, Дима the dollars of a flat by today, the
   person owes Саша until payday, and Ира and Папа gave everything back.

9. The phone has the debts in `debts_flutter`, and «Ещё» leads to them
   from the row «Долги» beside «Метки», which says what others owe and what
   the person owes:
   - the list adds both up in the currency of the totals, puts the debts
     with the nearest day first, shows a day that has come in amber, and
     keeps the settled ones in a fold;
   - the card says what is left of what, grows the bar of what came back,
     says the day and whether the phone reminds of it, and lists the steps;
     a tap on a step opens its operation;
   - a new debt, more money on one, a return and the terms are sheets. The
     return takes all that is left or a part, which it asks for at once;
   - a transfer of a debt in the operations shows the initial of the
     person in the color of the art of the debt, and opens the card of the
     debt;
   - the kit gets the glyph `people`, `InitialBadge`, the bright tint of an
     art (`CardArt.tint`), `GlassActionTile`, which the page of an operation
     used on its own, and `GlassValueRow`, which the form of a метка did.
10. The phone reminds of the day of an open debt that keeps the reminder:
    - at the time of the reminders and while their notifications are on
      ([ADR 0025](0025-reminders.md)), with «Срок сегодня · Маша, 3 000 ₽»,
      or without the amount when the reminders hide them, and a line that
      says who gives the money back. A tap opens the card of the debt;
    - `ReminderScheduler` puts these reminders among the ones of the
      payments, the earliest first, within the same limit of 60. The days
      come from the ledger (`watchDebtDays`): a debt that owes nothing,
      keeps no day or no reminder has none;
    - the calendar «Birka» keeps only the payments: its events repeat by a
      rule, and the day of a debt comes once;
    - the bell takes the day in at the same moment as a `DebtNotice` of the
      source «Долги» ([ADR 0026](0026-notifications.md)), whatever the
      switches say and in the demo too. The notice keeps the name and what
      was owed then; schema version 13 gives `notices` the column `debt_id`
      and a unique index on the debt and the day;
    - what became of the day is worked out from the ledger each time, from
      the round of the debt that the day falls in: the day it came back to
      nought («Вернули 2 ноября»), a part that came back, what is still
      owed, or that the debt is gone. A return can be deleted from its
      operation, so nothing of this is stored. A return that closes the
      debt marks its notices read, as what the person does to a payment
      does.
11. The site has the same pages (`debts_jaspr`) at `debts/`, with the card
    at `debts/#<id>`, more money at `debts/#more-<id>`, the terms at
    `debts/#edit-<id>` and a new debt at `debts/#new`. A wide window keeps
    the list and puts how the debts work, a card or a form beside it; a
    narrow one shows them in place of the list. The return opens in a fold
    under the actions of the card. The site has no reminders, so its forms
    have no switch, a day picked there turns none on, and one set on a phone
    stays. «Ещё» shows the totals under «Долги», and the operations lead to
    the card of a debt. The site kit gets `InitialBadge`, `CardArt.tint` and
    `GlassActionTile`, which the page of an operation drew on its own.

## Options considered

| Option | Why not |
|---|---|
| A table of debts beside the accounts | a second ledger of money with its own balances; a debt is money in a place, which an account already is |
| Loans as expenses and returns as income | they would swell the month and its reports with money that was never spent |
| One debt per person with a sign that flips | the history of a person who once lent and later borrowed would read one of the two ways wrong |
| Returns in any currency at the rate of the day | a debt agreed in dollars and repaid in rubles needs both amounts, which the boards do not draw yet |
| A side read from the order of the transfers | a list of operations would need the whole history of each debt to name one transfer |

## Consequences

- An account named after a person never shows among the accounts, so a
  debt is reached only through «Долги» and its operations.
- Writing off what is left, a debt in several currencies, splitting a bill
  and the debts in «Спросить» are not drawn yet.
