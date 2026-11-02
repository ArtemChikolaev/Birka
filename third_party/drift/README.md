# drift 2.31.0 with a fix from 2.35.1

The `lib` folder of [drift 2.31.0](https://pub.dev/packages/drift/versions/2.31.0)
with commit
[9d2330b](https://github.com/simolus3/drift/commit/9d2330b31f) of the drift
repository applied, "Handle unexpected close of drift remote client". Without
it a tab that closes in the middle of a transaction holds the shared worker of
the site forever ([ADR 0015](../../docs/adr/0015-drift-closed-tabs.md)).

drift 2.35 needs sqlite3 3.x, which waits for a Flutter upgrade
([ADR 0002](../../docs/adr/0002-toolchain.md)). That upgrade deletes this
folder and the override in the root `pubspec.yaml`.

- Only `lib` and `LICENSE` are here. The pubspec keeps the dependencies of
  drift and drops what drift needs for its own development.
- The commit is applied to `lib` alone. Its tests stay upstream, and ours are
  in `packages/core/database/test`.
- Nothing else here differs from the published package. The analysis and the
  formatting of the repository leave this folder alone.
