# ADR 0015 — drift 2.31 with the fix for closed tabs

**Status:** accepted 2026-11-02.

## Context

- On the site one drift server runs in a shared worker, and every tab is its
  client ([ADR 0009](0009-data-model.md)). A transaction is a conversation:
  the tab begins it, sends its statements and commits it, one message at a
  time.
- In drift 2.31 the server keeps every transaction at the head of its queue
  until the tab commits it or rolls it back. A tab that closes in between
  sends neither, so every later request of every tab of that browser waits
  forever. The pages stay on their placeholder until all tabs of the site are
  closed.
- Leaving a page right after Save is enough. On the live site it happened in
  3 of 10 tries of that step.
- Once it happened on the first visit of a browser: the tables of the new
  database reached IndexedDB, the version that drift writes after them did not,
  and every later opening failed on an index that already existed.
- drift 2.35.1 fixes the first part with commit 9d2330b. drift 2.35 needs
  sqlite3 3.x, which waits for a Flutter upgrade
  ([ADR 0002](0002-toolchain.md)).

## Decision

1. `third_party/drift` holds the `lib` of drift 2.31.0 as published, with
   commit 9d2330b applied, and the root `pubspec.yaml` overrides drift with it.
   Each tab holds a Web Lock while it lives, the worker gets that lock once the
   tab is gone, and the server rolls back what the tab left open.
2. The copy stays as published apart from that commit: the analysis and the
   formatting of the repository leave `third_party` alone, and the two commits
   that brought it in show the published code and the fix apart.
3. A first opening that stopped half way is finished by the next one: tables
   are created with `IF NOT EXISTS` already, and `onCreate` adds it to indexes.
4. The Flutter upgrade deletes `third_party/drift` and the override, and takes
   drift 2.35 or later.
5. A page that leaves closes its connection on `pagehide`, and one that the
   back button brings back loads again. Over a real network a page that has
   left stays alive for a while, frozen, with its Web Lock and its open
   transaction, so the fix of drift alone does not see it go: on the live site
   the next page still waited in 4 of 4 tries. Closing the connection sends
   the worker a goodbye at once, and the server rolls the transaction back.
6. A commit waits until IndexedDB holds it, through two more commits of drift:
   [bbcab2c](https://github.com/simolus3/drift/commit/bbcab2c866) hands the
   file system of the worker to its database, and
   [27004b3](https://github.com/simolus3/drift/commit/27004b3415) waits for it
   after a COMMIT too, which drift 2.31 skipped as part of a transaction. The
   `writeAutomatically: false` of the first one needs sqlite3 3.x and stays
   out, so writes start at once and the commit waits for them. Before, a commit
   came back while IndexedDB still had the transaction ahead of it. A form got
   away with it, since IndexedDB finished before the form closed: a tab closed
   right as the form closed lost nothing in 8 tries on the live site. Nothing
   promised the same for a long write, such as a restore from a copy. The page
   without shared workers no longer needs a flush of its own.

## Options considered

| Option | Why not now |
|---|---|
| Upgrade Flutter for drift 2.35 | a new toolchain for every package, a decision of its own (ADR 0002) |
| Writes as one batch instead of a transaction | the ledger reads inside its transactions, and a batch cannot |
| Tell the visitor to close all tabs after a timeout | the site stays broken, and the database of a first visit stays broken too |

## Consequences

- `packages/core/database/test` checks the server on the VM: a client that
  leaves in a transaction holds no one, and its write is undone. It fails
  without the fix.
- Leaving within a fraction of a second after Save, before the form closes,
  still loses that write: the tab is gone before the transaction ends. Once
  the form has closed, the write is in IndexedDB.
- A commit lasts until IndexedDB has stored it, and so does a read that finds
  writes still on their way. The overview of a local build showed its data
  about 50 ms later after its title: 190 ms instead of 140 ms with a shared
  worker, and 30 ms instead of 5-25 ms without one.
- A tab without Web Locks, Safari before 15.4, cannot be seen leaving when it
  is closed, and it behaves as before. A page that only leaves says goodbye
  in every browser.
- A page that comes back from the back-forward cache reloads instead of
  showing at once.
- Without shared workers the database lives in the page, which this does not
  touch: closing its storage on `pagehide` could let a frozen page write old
  data after the next one.
