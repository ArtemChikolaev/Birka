# drift 2.31.0 with fixes from 2.34.2 and 2.35.1

The `lib` folder of [drift 2.31.0](https://pub.dev/packages/drift/versions/2.31.0)
with three commits of the drift repository applied
([ADR 0015](../../docs/adr/0015-drift-closed-tabs.md)):

- [9d2330b](https://github.com/simolus3/drift/commit/9d2330b31f), "Handle
  unexpected close of drift remote client". Without it a tab that closes in
  the middle of a transaction holds the shared worker of the site forever.
- [bbcab2c](https://github.com/simolus3/drift/commit/bbcab2c866), "Flush
  IndexedDB file systems manually", without the `writeAutomatically: false`
  that sqlite3 2.9 does not have, so writes still start at once. With it the
  worker hands its file system to the database, which can wait for it.
- [27004b3](https://github.com/simolus3/drift/commit/27004b3415), "Web: Flush
  IndexedDB after transactions and RETURNING statements". With it a commit
  waits until IndexedDB holds the transaction, so a tab that closes once a
  save is done loses nothing, however long the write was.

drift 2.35 needs sqlite3 3.x, which waits for a Flutter upgrade
([ADR 0002](../../docs/adr/0002-toolchain.md)). That upgrade deletes this
folder and the override in the root `pubspec.yaml`.

- Only `lib` and `LICENSE` are here. The pubspec keeps the dependencies of
  drift and drops what drift needs for its own development.
- The commits are applied to `lib` alone. Their tests stay upstream, and ours
  are in `packages/core/database/test` and in the scenarios of the site.
- Nothing else here differs from the published package. The analysis and the
  formatting of the repository leave this folder alone.
