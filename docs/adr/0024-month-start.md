# ADR 0024 — The day a month starts on

**Status:** accepted 2026-11-07.

## Context

- Many people live from one salary to the next. When the salary comes on
  the 5th or the 25th, a calendar month cuts what they spend between two
  salaries in two.
- The boards «Ещё» and «Деньги до зарплаты» draw the row «Начало месяца»
  with its day. On the second board it reads «для обзора и отчётов», and a
  hint under it offers to start the month on the payday.
- The overview counts the spending of the month, and the reports compare
  months ([ADR 0012](0012-exchange-rates.md)). The money until the salary
  can count until the end of the month
  ([ADR 0023](0023-regular-payments.md)).
- The settings of a device live outside the database
  ([ADR 0011](0011-settings.md)).

## Decision

1. The day is a setting of the device, `Settings.monthStart` under the key
   `month-start`, from 1 to 28: the days that every month has. Any other
   value, or none, starts the months on the 1st.
2. `MonthStart` in `device_settings` holds the day for the screens and tells
   them when it changes, as `BaseCurrency` does for the currency. The
   settings write it, and the overview, the reports and the money until the
   salary follow it at once.
3. A month runs from its day to the day before it in the next month, and it
   is named after the month it starts in. With the 25th, «Ноябрь» runs from
   25 November to 24 December.
   - `CivilDate.monthStart(day)` gives the first day of the month that holds
     a date.
   - `CivilDate.addMonths` steps from one month to the next.
4. The overview counts the spending of that month and starts the chart of
   the month on its first day.
5. The reports compare those months, the same days of the month before
   included. They list the months with operations by those days
   (`LedgerRepository.months(start:)`), which the SQL groups.
6. The operations and the page of an account stay on the calendar. They go
   by days, the way a bank statement does, and the board names only the
   overview and the reports.
7. The money until the salary counts «до конца месяца» until the day before
   the next month starts: with the 5th, until the 4th.
8. The settings ask for the day in a sheet of the 28 days, with «как в
   календаре» under the 1st.
   - The page of the money until the salary shows the same row in its group
     with «Отложить до зарплаты» and opens the same sheet. The host keeps
     the setting.
   - Under the row, a hint offers the day of a monthly salary when the months
     start on another day: «Зарплата приходит 5-го: месяц можно начинать с
     этого дня, тогда ноябрь — с 5 ноября по 4 декабря.»
   - A salary past the 28th gets no hint.
9. The site has no row yet, so it keeps the stored day, the 1st, until its
   boards come.

## Options considered

| Option | Why not |
|---|---|
| Days 29 to 31 | February has no 29th most years. A month that starts on the 31st would start on a different day in half the months |
| The day in the database | it is a way of looking at the ledger, not data, and no stored row depends on it |
| Months of the operations from that day too | the operations go by days, as a bank statement does, and the board names only the overview and the reports |
| A month named after the month it ends in | the hint of the board names the month from the 5th of November «ноябрь» |
| A second control on the page of the money until the salary | the setting is one, so it is one row in two places |

## Consequences

- A new day shows at once on the overview and in the reports, since every
  total is computed when it is read.
- The copy of the ledger does not carry the day, because it carries no
  setting.
- With a day other than the 1st, a month in the reports and a month of the
  operations are different days.
