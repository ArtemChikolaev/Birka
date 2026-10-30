# ADR 0006 — Feature-first packages with Clean layers inside

**Status:** accepted 2026-10-30.

## Context

- Birka will grow to a dozen features: accounts, transactions, budgets,
  reports, import, settings and more. Each one has logic that the Flutter app
  and the Jaspr web app share.
- A layer-first layout, with all data code in one place and all screens in
  another, spreads one feature over the whole tree: a change to budgets means
  visiting five folders, and it gets worse with every feature.
- A few things are shared by many features: money, the one local database,
  the rules every write to the ledger must keep, exchange rates, strings and
  networking.
- The pure-Dart code must stay apart from Flutter and Jaspr
  ([ADR 0001](0001-single-repository.md)).

## Decision

1. A feature lives in one folder, `packages/features/<feature>/`, as up to
   three packages:
   - `common/` is pure Dart and shared by both apps. `lib/src/data/` holds
     repository implementations, mappers and queries over the database;
     `lib/src/domain/` holds models, repository interfaces and use cases;
     `lib/src/presentation/` holds the BLoCs and their states; `lib/src/di/`
     holds the function that registers the feature in `get_it`.
   - `flutter/` is the Flutter UI: `lib/src/presentation/pages/` and
     `widgets/`.
   - `jaspr/` is the Jaspr UI: `lib/src/presentation/pages/` and
     `components/`.
2. Inside `common`, the dependency rule of Clean Architecture holds:
   `presentation → domain ← data`. The domain knows nothing about the
   database or the UI, BLoCs talk to repository interfaces, and the data
   layer implements them.
3. `packages/core/<package>/` holds only what several features share:
   `money`, the one Drift `database` with its migrations, the `ledger`
   (shared entities such as accounts, transactions and categories, and the
   rules every write keeps), `rates`, `l10n` (one file of strings per
   feature), `network` (Dio) and, later, `sync`. Core packages are pure Dart.
4. `packages/design/` is the design system: tokens, chart geometry, the
   Flutter and Jaspr kits and the catalog.
5. The hosts in `apps/` are the composition roots: `mobile` for Android and
   iOS, which also runs on macOS during development as the quickest loop,
   and `web` for the browser. They call each feature's registration
   function, build the router and pick the theme and the locale. `get_it`
   appears only in the hosts and in those registration functions; every
   other class gets its dependencies through its constructor.
6. Features never depend on each other. A screen that combines several
   features, such as the overview, is a feature of its own that reads from
   the core.
7. `make check-deps` enforces the package rules: pure Dart where required,
   no Flutter in Jaspr packages and no Jaspr in Flutter ones, no
   feature-to-feature dependencies, and the core and the design system
   depend on nothing above them. The direction of imports inside `common`
   will be checked once the first feature lands.

## Options considered

| Option | Why not |
|---|---|
| Layer-first zones at the top (`entities/`, `data/`, `shared/` as in Feature-Sliced Design) | one feature is spread over many folders, which gets harder to navigate with every feature |
| A package per layer of a feature (`data`, `domain`, `presentation`) | five packages per feature for little gain: the layers inside `common` are folders, and the rule between them can be checked by imports |
| A database per feature | features share accounts, transactions and categories, and one schema keeps migrations in one history |
| `get_it` lookups inside feature classes | hides dependencies and makes every test set up a global container |

## Consequences

- A new feature is one folder with up to three packages; a template will
  generate it.
- The core must stay small: something moves there only when a second
  feature needs it.
- `money` moved from `packages/money` to `packages/core/money`.
