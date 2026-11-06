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
   1 and 2 without them. It checks a payment as the ledger checks one that it
   adds, and holds only the payments whose accounts and category travel with
   them, so that every copy restores.
9. The screens, the reminders, how much can be spent today, the payday and
   the first day of a month come with their own changes and add their points
   here.

## Consequences

- The days ahead are counted from the rules and the ledger each time, so a
  change of a payment shows at once everywhere.
- No transaction names the rule that gave it. An import that brings a
  payment the person posted is caught by the check for copies
  ([ADR 0021](0021-statements.md)); marking a waiting payment done from a
  statement comes with its own change.
