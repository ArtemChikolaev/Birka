# CLAUDE.md — Birka

Rules for everyone who changes this repository, people and coding agents
alike. `AGENTS.md` is a symlink to this file.

## Project

Birka is a local-first expense tracker for money across currencies, banks and
countries. A pure-Dart core is shared by a Flutter app (Android and iOS; it
also runs on macOS during development) and a Jaspr web app; a small Go server
for end-to-end encrypted sync comes later.
Decisions live in [docs/adr](docs/adr/), the mockups of the first version in
[docs/design](docs/design/).

## Rule 0 — Reuse first

Before writing code or adding a dependency, look for an existing package,
type or helper in this repository and among the dependencies we already have.
Extend what exists instead of duplicating it.

## Pillars

- **Local-first.** The UI reads only the local database; network work
  catches up in the background.
- **Exact money.** Amounts are integers in minor units
  ([ADR 0003](docs/adr/0003-money-representation.md)).
- **One core, two hosts.** Logic lives in pure Dart; Flutter and Jaspr only
  render and wire dependencies.
- **Private by default.** No bank passwords, no real personal data in the
  repository, nothing readable on the server.

## Architecture and boundaries

- Layout ([ADR 0006](docs/adr/0006-feature-first-packages.md)):
  - `packages/features/<feature>/` holds everything about one feature:
    `common/` (pure Dart: `data/`, `domain/`, `presentation/` with the
    BLoCs, `di/`), `flutter/` and `jaspr/` (pages and widgets or
    components);
  - `packages/core/` holds only what several features share: money, the
    database, the ledger rules, rates, strings, networking;
  - `packages/design/` is the design system, `apps/` are the hosts, and the
    server lives in `server/` and `proto/`
    ([ADR 0001](docs/adr/0001-single-repository.md)).
- Inside `common`, `presentation → domain ← data`: the domain imports
  neither the database nor the UI.
- Core packages and every `common` package are pure Dart: no `flutter`, no
  `jaspr`. Flutter packages never use Jaspr, and Jaspr packages never use
  Flutter.
- A feature never depends on another feature. Code that a second feature
  needs moves to the core.
- `get_it` appears only in the hosts and in each feature's registration
  function; every other class gets its dependencies through its
  constructor.
- The design system knows nothing about money or features.
- Colors, sizes, type and motion come from the design tokens
  ([ADR 0007](docs/adr/0007-design-tokens.md)): change them in
  `packages/design/tokens/tokens/` and run `make tokens`, never edit the
  generated files, and never hard-code a color or a size that a token has.
  Flutter widgets read `BirkaColors.of(context)` and
  `BirkaTextStyles.of(context)`.
- Our packages depend on each other through `path:`.
- `make check-deps` enforces these rules in CI. Fix the code, not the rule.

## Money and data invariants

- `Money(minorUnits, currency)`: `int` minor units within ±(2^53 − 1), never
  `double`. No bitwise operators on amounts: on the web they work on 32 bits.
- Split amounts with `Money.allocate`; never divide and round by hand.
- Exchange rates are `Decimal` with an explicit rounding mode.
- A transaction date is a civil date; period boundaries use the user's time
  zone.

## Toolchain

- Flutter 3.38.10 and Dart 3.10.9, pinned in `.fvmrc`
  ([ADR 0002](docs/adr/0002-toolchain.md)). Never upgrade it as a side effect
  of another change.
- Take versions from ADR 0002 and write explicit caret constraints, never
  `any`.
- Never name a package like a pub.dev package such as `web`, `test` or
  `http`: the hosts are `birka_mobile` and `birka_web`.

## Privacy and security

- Test fixtures are synthetic. Real statements, exports and screenshots with
  data stay in `private/`, which git ignores.
- Never commit secrets, keystores or tokens; CI reads them from GitHub
  secrets.

## Process

- Every change lands through a pull request into `main` with green checks,
  merged with squash. Rulesets enforce it for everyone, the owner included,
  and pull requests from anyone else also need the owner's approval
  ([ADR 0004](docs/adr/0004-branches-and-releases.md)).
- The only required check is `All checks` in `ci.yml`. Add every new CI job
  to its `needs`, keep the advisory Claude review out of it, and never put
  path filters on a workflow with required checks.
- Claude reviews pull requests that change code
  ([ADR 0005](docs/adr/0005-claude-review.md)). Fix Important findings,
  answer the rest and resolve every thread. The `claude-review` label asks
  for a review of any pull request, `claude-opus` for a stronger model.
- PR titles follow Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`);
  the description says what, why and how it was verified.
- Code, docs, commits and comments are in English.
- Push is not deploy: after a merge, wait for CI and check the result.

## Before "done"

Run `make check`. After changes in core packages also run
`make test-core COMPILER=dart2js` and `make test-core COMPILER=dart2wasm`.
When a decision or a command changes, update the ADR or the README in the
same pull request.
