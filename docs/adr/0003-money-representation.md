# ADR 0003 — Money as integer minor units

**Status:** accepted 2026-10-29.

## Context

- The same Dart core runs on the VM (Android, iOS), dart2js and dart2wasm
  (web). On the web an `int` is a JavaScript number: integers are exact only
  up to 2^53 − 1, and bitwise operators work on 32 bits.
- `double` cannot hold 0.10 exactly, so sums drift by a minor unit.
- Splitting an amount, for a shared bill or a split transaction, must neither
  lose nor create a kopeck.

## Decision

1. An amount is `Money(minorUnits, currency)`: an `int` number of minor units
   (kopecks, cents) and a `Currency`.
2. The number of minor-unit digits follows ISO 4217 (RUB 2, JPY 0, KWD 3,
   CLF 4). Currencies outside ISO 4217 declare their own, up to 8, which is
   enough for BTC.
3. Every amount stays within ±(2^53 − 1) minor units. Operations that would
   leave the range throw instead of losing precision. Multiplication checks
   the range before multiplying, because on the VM a 64-bit product can wrap
   around silently.
4. Allocation gives each part its exact share rounded toward zero, then hands
   the leftover minor units out one by one to the parts whose shares lost the
   most in rounding, earlier parts first on a tie (the largest remainder
   method). Every part is its exact share rounded down or up, and the parts
   always add up to the amount. Intermediate products use `BigInt`, so they
   stay exact on every platform. Handing the leftover simply to the first
   parts was rejected: a property test showed that it can add a kopeck to a
   share that was already exact.
5. Parsing reads decimal strings digit by digit and rejects extra fraction
   digits instead of rounding. Formatting for people (grouping, symbols,
   locales) belongs to the localization layer, not to `money`.
6. Exchange rates will be `Decimal` with an explicit rounding mode; currency
   conversion lives outside `money`.
7. CI runs the core tests on the VM, dart2js and dart2wasm.

## Options considered

| Option | Why not |
|---|---|
| `double` | inexact for decimal fractions |
| `Decimal` for amounts | slower, and a stored amount never needs more digits than its currency has |
| `BigInt` for every amount | slow on the web, while 2^53 − 1 kopecks is about 90 trillion rubles |
| The `money2` package | money is the heart of the domain: we keep the type small, our own and fully tested |

## Consequences

- The keypad of quick add works sums out in fractions of `BigInt` and rounds
  once, at the end, to the minor units with halves away from zero. So `0.1 +
  0.2` is exact and `100 ÷ 3 × 3` gives 100.
- Tokens with 18 digits, such as ETH counted in wei, are not supported. With 8
  digits the limit is about 90 million whole units.
- Amounts are integers in storage and in sync messages; the database never
  sees a floating-point amount.
