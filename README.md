# Birka

Local-first expense tracker for money across currencies, banks and countries.

**Status:** early development. The repository is being set up; there is
nothing to install yet. The first milestone is manual tracking with several
currencies and reports.

## Why

Our money lives in several currencies, banks and countries. The trackers we
tried either keep one currency per budget, ask for bank passwords, or keep our
data on their servers. Birka is the tracker we are building for ourselves:
the data stays on the device, every amount keeps its own currency, and reports
convert at the rate of the day. We plan to keep developing it.

The name comes from the *birka* (бирка), an old tally stick on which debts were
recorded with notches, and from Birka, a Viking Age trading town where coins
from many countries changed hands.

## What it will do

- Accounts in any currency: cash, cards, deposits, loans.
- Expenses, income and transfers between currencies at the actual rate.
- Categories, budgets, recurring payments and reports in a base currency.
- Import from bank statements (CSV, OFX) instead of bank passwords.
- Android, iOS and the web from one codebase; the data stays on the device.
- Later: end-to-end encrypted sync through a small self-hosted server.

## How it is built

- **One pure-Dart core** (money, domain rules, storage, BLoC state) shared by
  two thin hosts: a **Flutter** app for Android and iOS and a **Jaspr** web app.
- **Local-first:** SQLite through Drift on every platform, including the web.
- **Exact money:** amounts are integers in minor units, never `double`. Core
  tests run on the Dart VM, dart2js and dart2wasm, so every platform computes
  the same result ([ADR 0003](docs/adr/0003-money-representation.md)).
- **One repository, three zones:** the app, the design system and, later, a Go
  sync relay ([ADR 0001](docs/adr/0001-single-repository.md)).
- **Toolchain:** Flutter 3.38.10 and Dart 3.10.9
  ([ADR 0002](docs/adr/0002-toolchain.md)).

## Repository layout

```text
packages/money   Money and Currency value types
tools            repository tooling: package boundary checks
docs/adr         architecture decision records
```

## Getting started

You need Flutter 3.38.10 (pinned in `.fvmrc`) and GNU Make.

```bash
make bootstrap                      # fetch dependencies
make check                          # format, analysis, boundaries, tests
make test-core COMPILER=dart2wasm   # core tests in Chrome via WebAssembly
```

## Contributing

Every change, ours included, lands in `main` through a pull request with green
checks, and changes from other contributors also need the maintainer's
approval; repository rulesets enforce both
([ADR 0004](docs/adr/0004-branches-and-releases.md)). Pull requests that
change code also get an advisory review from Claude
([ADR 0005](docs/adr/0005-claude-review.md)). People and coding agents follow
the same rules: [CLAUDE.md](CLAUDE.md).

## License

[MIT](LICENSE)
