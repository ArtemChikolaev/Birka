# ADR 0012 — Rates of the Bank of Russia, kept on the device

**Status:** accepted 2026-11-01.

## Context

- A total across currencies needs rates. Screens read only the local database
  ([ADR 0009](0009-data-model.md)), so rates have to be kept there, and a
  screen must never wait for the network.
- The site runs in a browser. `cbr.ru` sends no CORS headers, while
  `cbr-xml-daily.ru` mirrors it as JSON with `Access-Control-Allow-Origin: *`.
  Its terms ask for at most one request a second, 30 a minute and 10 000 a day
  from one address, and for a link back.
- The mirror covers every currency that Birka offers except USDT, and has an
  archive by date. The ECB through Frankfurter has no ruble.

## Decision

1. Both hosts read one source, `CbrMirror`, through the same code. A rate is a
   price in rubles, and any two currencies meet through the ruble.
2. `packages/core/rates` holds the rates. A rate is a `Decimal`, the arithmetic
   is exact through `Rational`, and the result rounds once, half away from
   zero. A total that took a rate rounds to whole units, since it is only as
   exact as the rate, unless it is less than one unit. What never took a rate
   keeps its kopecks.
3. `exchange_rates` holds a price for each day and currency that Birka offers,
   as a decimal string. Any device can fetch these again, so the table has no
   `SyncedRow` columns and no outbox.
4. `RatesUpdater.refresh` runs beside the first frame and when the app comes
   back, and on the site once a page has its database. It asks for nothing when
   the latest rates are for today or later. A failure is quiet and the last
   rates stay, and a request gives up after 15 seconds.
5. The base currency is a setting of the device
   ([ADR 0011](0011-settings.md)). No stored amount depends on it, because every
   total is computed when it is read, and More keeps working without the
   database. With none picked, totals follow the first account, as they did.
   `BaseCurrency` in the core carries the choice to the screens.
6. The capital uses the latest rate ([ADR 0009](0009-data-model.md)), and so
   does every change on its chart, so that the line follows the money and not
   the rates.
7. A report and the spending of the month take the rate of each day
   ([ADR 0009](0009-data-model.md)), so the ledger gives them totals by day and
   the rates add those up. A day without a rate takes the last one before it,
   and a day before them all takes the first, so that a history on its way
   leaves no total without a value.
8. After the latest rates `refresh` brings the days that have expenses or income
   outside the currency of totals, the latest first: at most 25 requests a run,
   two seconds apart, which stays within the terms of the mirror, and it stops
   at the first failure. The next run goes on from there. A call during a run
   drops the days it was after and starts on the days needed now, so a base
   currency picked in the first minute gets its days at once. A day that the
   Bank of Russia skipped keeps the rates of the last day before it, up to 12
   days back, so that it is never asked for again. Nothing that far back ends
   the run.
   The mirror answers such a day with a 404 that has no CORS header, which a
   browser reports as a failed request, so on the site a failed request for a
   past day counts as a skipped day. A request lost there leaves that day with
   the rate before it, and a request that hangs still stops the run.
9. An amount without a rate stays apart, in its own currency, and never counts
   as zero.
10. USDT counts as a dollar until crypto has rates of its own.
11. More links to the source on the site and names it in the app, as its terms
    ask.

## Options considered

| Option | Why not |
|---|---|
| `cbr.ru` on phones and the mirror on the site | two parsers for the same numbers, one of them for XML in windows-1251 |
| Frankfurter for pairs without the ruble | a second source for no new currency, and cross rates that disagree with the first |
| `open.er-api.com` | a commercial source with less history, while the Bank of Russia is what a person here compares with |
| A proxy of our own | a server to run for a public file, and the first thing to know the address of every user |
| Dio | interceptors and adapters for one GET; `http` is already in the lockfile |
| The base currency in the database | More would have to open the database for one row, and sync, which might want it there, does not exist yet |
| Keeping a total in the base currency | a new base currency would mean rewriting what the ledger never needs |

## Consequences

- This is the first time Birka talks to a network. A request carries nothing of
  the user, but the mirror sees an address. Android gets the `INTERNET`
  permission and macOS `com.apple.security.network.client`.
- Rates are a day old at best, and the first launch without a connection has
  none: each currency then stands apart.
- A new source only has to implement `RateSource`.
- `make check-site` ignores failed requests to other hosts, because the mirror
  being down says nothing about the site.
- A long history takes several launches to arrive, and until then a report
  moves a little as the rates of its days come in. A report in one currency
  needs no rate and never moves.
- The bar of a month is the sum of its categories, each rounded on its own, so
  that the two can never disagree on the same page.
