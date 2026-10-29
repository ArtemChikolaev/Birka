# ADR 0002 — Flutter 3.38.10 and the package versions it allows

**Status:** accepted 2026-10-29.

## Context

- We pin Flutter 3.38.10 (Dart 3.10.9) to keep one toolchain across our
  projects, and move to a newer Flutter only on purpose.
- A pub workspace resolves all packages together. When a workspace contains a
  Flutter package, the Flutter SDK pins part of the graph: `flutter_test` pins
  `test_api` 0.7.7, which allows only `test` 1.26.3, which allows only
  `analyzer` below 9. Every code generator in the workspace inherits that
  limit.
- On 2026-10-29 we resolved the full planned stack with `flutter pub get` to
  see what this means in practice.

## Decision

1. Flutter 3.38.10 is pinned in `.fvmrc`; CI reads it through
   `subosito/flutter-action` (`flutter-version-file`).
2. Code generation stays on the analyzer 8 generation. These versions
   resolve together:

| Area | Packages | Versions |
|---|---|---|
| Code generation | build_runner, analyzer | 2.15.1, 8.4.0 |
| Web | jaspr, jaspr_builder, jaspr_router, jaspr_bloc, jaspr_test, jaspr_lints, jaspr_cli | 0.22.3, 0.22.3, 0.8.1, 1.0.1, 0.22.3, 0.6.0, 0.22.3 |
| Storage | drift, drift_dev, drift_flutter, sqlite3 | 2.31.0, 2.31.0, 0.2.8, 2.9.4 |
| State | bloc, flutter_bloc, bloc_test, bloc_concurrency | 9.2.1, 9.1.1, 10.0.0, 0.3.0 |
| Navigation and DI | go_router, get_it | 17.5.0, 9.3.0 |
| Strings | slang, slang_flutter | 4.19.2, 4.19.0 |
| Testing and lints | test, mocktail, very_good_analysis | 1.26.3, 1.0.5, 10.1.0 |
| Monitoring | sentry_flutter | 9.30.1 |
| Sync client (later) | connectrpc, protobuf | 2.0.1, 6.1.0 |

3. Every dependency gets an explicit caret constraint taken from this table.
   With `any`, pub picked `sentry_flutter` 8.14 although 9.30 resolves: it
   looks for one valid solution, not for the newest version of every package.
4. The web host uses the published `jaspr_bloc`, which requires Jaspr 0.22,
   instead of a hand-written bridge.
5. `jaspr_cli` is a dev dependency, so the CLI has the same version locally
   and in CI.
6. Workspace members are listed one by one in the root `pubspec.yaml`: globs
   need Dart 3.11.
7. No workspace package is named like a pub.dev package that something
   depends on. A host called `web` breaks resolution because drift and Jaspr
   depend on `package:web`, so the hosts are `birka_mobile` and `birka_web`.

## Options considered

| Option | Why not |
|---|---|
| The latest Flutter, 3.47.8 | a second toolchain to keep; we upgrade on purpose |
| The web host outside the workspace, to get Jaspr 0.23 | two lockfiles and committed generated code for a release whose changes are mostly in the CLI |

## Consequences

- drift 2.32+, sqlite3 3.x with build hooks, Jaspr 0.23, go_router 18 and
  sentry 10 wait for a Flutter upgrade. Every upgrade starts with the same
  resolution check and an update of this ADR.
- On Flutter 3.38.10 the native SQLite library comes through
  `sqlite3_flutter_libs` (a dependency of `drift_flutter`), and the web build
  needs `sqlite3.wasm` and `drift_worker.js` from the matching releases.
- pub updates from Dependabot are off; GitHub Actions updates stay on.
