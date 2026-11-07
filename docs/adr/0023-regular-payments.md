# ADR 0023 — Regular payments

**Status:** accepted 2026-11-06.

## Context

- People pay the rent, subscriptions and bills, and get a salary, on days
  they know. The second cycle after the MVP shows what is ahead: the
  payments of the next 30 days and how much can be spent each day until the
  salary.
- The ledger holds what happened ([ADR 0009](0009-data-model.md)). A planned
  transaction is one known operation ahead, but a payment that comes again
  every month without an end cannot be a row per time.
- A statement can bring an operation that the person has already recorded
  by hand ([ADR 0021](0021-statements.md)).
- Everything stays on the device and travels in the copy of the ledger
  ([ADR 0016](0016-ledger-copy.md)).

## Decision

1. A regular payment is a rule: `Schedule` in `packages/core/ledger`, in a
   table of its own, `schedules`, from version 5 of the schema. It holds the
   kind (an expense, an income or a transfer), the name, the account, the
   account a transfer reaches, the category or none, the positive amount in
   the currency of the account, how often it comes (`month`, `week`,
   `year`), its day of the month, the date of its next time, what its day
   does and when to remind of it. Its later times follow from the rule and
   are stored nowhere.
2. A monthly payment falls on its day, or on the last day of a shorter
   month, and comes back to its day after that; a weekly one comes seven
   days later; a yearly one comes on its day of the same month a year later.
   A time posted on another day still leads to the next time of the rule.
3. «Провести» (`postSchedule`) records the next time as a transaction of its
   own and moves the payment on to its time after that, in one write. The
   transaction falls on that time unless the person gives another day, takes
   the amount of the rule unless the person gives another one, as for a bill
   that changes, takes the name as its note and comes from the source
   `recurring`. «Пропустить» (`skipSchedule`) moves the payment on with no
   transaction. A payment without a category gives transactions that wait in
   the inbox ([ADR 0022](0022-inbox.md)).
4. A payment that posts itself (`ScheduleOnDay.post`) is posted by
   `postDueSchedules`: every time that has come, the ones missed while the
   app was closed included, in one write. A payment that asks
   (`ScheduleOnDay.ask`) waits for the person from its day on.
5. A write keeps the rules: a name, a positive amount in the currency of the
   account, a day from 1 to 31, accounts and a category that exist, a
   category of the kind of the payment, and a transfer between two different
   accounts of one currency with no category. A regular payment never
   adjusts a balance. A transfer between currencies needs both amounts and
   stays out for now.
6. A change puts a new rule in place of the old one, and a deletion leaves a
   tombstone; the transactions the payment gave stay as they are. Every write
   leaves its change in the outbox, as for the other rows.
7. The undo of an import keeps an account or a category that it added while a
   regular payment uses it, as while an operation does
   ([ADR 0021](0021-statements.md), point 11).
8. The copy of the ledger is version 3, with `schedules`, and reads versions
   1 and 2 without them; version 4 adds point 14. It checks a payment as the
   ledger checks one that it adds, and holds only the payments whose
   accounts and category travel with them, so that every copy restores.
9. The phone shows them as the boards «Будущие деньги на телефоне» of the
   canvas draw them, in `packages/features/schedules`: `schedules_common`
   holds the rules of the screens and `schedules_flutter` the screens.
   - The overview gets a card above the inbox strip: what today may still
     take, a bar of what it took, the three nearest payments and the way to
     all of them. Without a salary to count until it asks for the payday,
     and without accounts it stays away.
   - «Регулярные платежи» lists the payments that wait for the person with
     «Провести» and «Пропустить», the next 30 days and every payment.
   - The form of a payment is a sheet, as the other forms are
     ([ADR 0017](0017-motion.md)). Its name and amount come from a sheet with
     one field, which the note of an operation now shares.
   - «Деньги до зарплаты» shows the sum in the open: what the counted
     accounts held this morning, the payments until the end, what stays
     aside, and the days.
10. How much a day may take (`SpendingPlan`): the money of the counted
    accounts as it was in the morning, less the payments that leave them
    until the end and what stays aside, split evenly between the days left,
    today included, in whole units of the currency.
    - The end is the day before the salary, the nearest time after today of a
      regular income to a counted account, or the last day of the month.
    - The payments are the regular expenses from the counted accounts and
      the regular transfers from them to others, the ones that wait
      included. Regular incomes before the salary do not count, so that the
      plan never promises money that may not come.
    - What the person spent today on the counted accounts comes out of
      today's share only; the transactions of regular payments are part of
      the payments instead. Once today took more than its share, the card
      says what each day after it may take.
11. The device keeps until when it counts, which accounts and what stays
    aside, as it keeps its other settings ([ADR 0011](0011-settings.md)). It
    counts the debit cards and the cash in the base currency until told
    otherwise; an account in another currency cannot be counted yet.
12. The app posts the payments that post themselves when it starts and
    whenever it comes back to the screen.
13. Reminders need a plugin for notifications, the first day of a month is a
    setting of its own, and the site gets its boards first; they come with
    their own changes and add their points here.
14. A payment keeps what was done to its last times (`ScheduleLast`, from
    version 6 of the schema): posted, skipped or found in a statement, the
    first and the last of those times, the transaction of the last one, the
    import of the statement and when. «Провести», «Пропустить» and
    `postDueSchedules` write it in the same write that moves the payment on.
    A change of the payment keeps it unless its next time moves, since then
    what was done no longer leads to it.
15. A statement brings a time of a regular payment as it brings a copy of a
    transaction ([ADR 0021](0021-statements.md), point 14): an operation of
    the kind of the payment moves its amount on its account, or on both of
    its accounts for a transfer, within a day of that time, and a name that
    shares a word makes it likelier. The times come from the next one on,
    one after another up to a day after the statement ends, and each
    operation brings one time at most. An operation that stays out as a
    copy brings it too, since the bank says that the payment went through.
16. `ImportRepository.write` marks those times done (`findSchedule`) in the
    write of the import: the payment moves on with no transactions of its
    own, so nothing posts or asks for them again, and the operation of the
    statement, or the transaction it is a copy of, stands for the last one.
    The undo of the import moves the payment back to the first of them.
17. On the day something was done to a payment, its line in «Регулярные
    платежи» says what: «проведён сегодня», «пропущен» or «нашли в выписке»,
    with its next time, in the color of a gain unless it was skipped; on
    other days it says how often the payment comes. On the day of an import,
    a payment that the statement brought says so at the top of the list, in
    a notice that names the bank when Birka knows the format.
18. A regular payment can come twice a month (`advanceDay`, from version 7
    of the schema): a salary paid in halves, its advance on that day and the
    rest on its own day, each time with the amount of the rule. The times
    alternate, and each keeps to the last day of a shorter month. Only a
    monthly payment has an advance, on another day than its own. The lists,
    the toasts and the line of what was done call the advance «Аванс»; its
    transactions keep the name of the payment. The copy of the ledger is
    version 5 with `advanceDay`.
19. The form of an income asks how it comes, «Одной суммой» or «С
    авансом». With the advance, its amount is what comes in a month and is
    saved as two equal halves (an odd minor unit goes), and its two days take
    the place of «Повторять каждый». The next time is the nearest of the two
    days, and it moves only when a day does, so an advance that waits for the
    person stays through a change.
20. The money of the days counts until the salary, not until its advance:
    an advance before the end comes in as income, in the open sum («Аванс 20
    ноября +60 000 ₽»), as sure as the salary itself. Until the first advance,
    a day takes no more than the counted accounts allow without it, less the
    payments before it and what stays aside, and the sum says so («До аванса
    20 ноября хватает: 19 600 ₽ на 2 дня»); when those days lack money, the
    sum says what they lack. The row of the payday reads «Аванс и зарплата ·
    20-го и 5-го».

## Consequences

- The days ahead are counted from the rules and the ledger each time, so a
  change of a payment shows at once everywhere.
- No transaction names the rule that gave it. An import that brings a
  payment the person posted is caught by the check for copies
  ([ADR 0021](0021-statements.md)), and one that brings a payment that
  waits marks it done; only the last done times point at a transaction.
- A bill whose amount changes is found only when the statement brings the
  amount of the rule. Otherwise the person posts it with its own amount,
  and the check for copies then keeps the operation of the statement out.
- The copy of the ledger is version 4, with what was done to the last times
  of each payment, and reads version 3 without it; version 5 adds the day of
  an advance.
- Counting until the advance instead would let the days before it spend
  what the payments after it need: on the boards, 39 800 ₽ a day for two
  days, then little until the salary.
