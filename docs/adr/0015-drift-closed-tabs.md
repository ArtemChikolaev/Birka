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
  still loses that write: the tab is gone before the transaction ends.
- A tab without Web Locks, Safari before 15.4, cannot be seen leaving, and it
  behaves as before.
