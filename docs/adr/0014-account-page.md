# ADR 0014 — The page of an account lives with the operations

**Status:** accepted 2026-11-01.

## Context

- Tapping an account opened its form, so there was no place to see how a balance
  got where it is.
- The page shows an account, a chart of its balance and its operations. Accounts
  and operations are two features, and features never depend on each other
  ([ADR 0006](0006-feature-first-packages.md)).
- The rows of operations, with their swipes and the sheet that deletes, are
  widgets of the transactions feature, and a widget cannot move to the core.
- The chart needs the same periods as the chart of the capital.

## Decision

1. The page lives in the transactions feature: `AccountCubit` and `AccountPage`.
   Most of it is a list of operations, and that feature reads accounts from the
   ledger anyway. The accounts feature keeps the list of accounts and the form.
2. An account opens on its page, `/accounts/:id`, and the form moves to
   `/accounts/:id/edit`, behind a button on the page. The form still corrects the
   balance.
3. `ChartPeriod` and `balanceHistory` moved from the overview to `ledger`, and the
   names of the periods to `l10n`, which takes the name of a period as a string,
   as `accountLine` does, because it cannot know the ledger.
4. The chart counts entries of this account only, whether or not the account
   counts towards totals. It is in the currency of the account, so it needs no
   rates.
5. The list shows the latest 200 operations of the account. Older ones stay in
   the operations of their month.
6. On this page a transfer has a sign, what it did to this account, instead of
   the quiet amount of the list of operations. The heading of a day adds up the
   same amounts, corrections included, so it agrees with its rows and the chart.

## Options considered

| Option | Why not |
|---|---|
| A feature of its own, as the overview | it would need the rows of operations, which only a feature can hold, so they would live twice |
| The page in the accounts feature | it would depend on the transactions feature or redraw its rows |
| Every operation of the account | a long history would be read in full to show its first screen |
| The operations of the period of the chart | a year of them would load just to show a chart, and a week would hide what is older |

## Consequences

- The first days of a month draw a short line on the default period, as the
  overview does.
- The transactions feature now reads day changes and balances from the ledger.
