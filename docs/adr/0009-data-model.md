# ADR 0009 — The data model: a ledger of entries in one Drift database

**Status:** accepted 2026-10-30.

## Context

- Money moves between accounts, currencies and banks. A transfer between
  currencies has two amounts, and a purchase can split across categories.
- Birka is local-first: the UI reads only the local database, on phones and
  in the browser, and sync comes later.
- The same queries should run everywhere, so that reports are written once.
- GitHub Pages cannot send COOP and COEP headers, which limits storage in the
  browser ([ADR 0008](0008-web-host.md)). A spike measured what Drift gets
  under `/Birka/` without them:

| Browser | Storage Drift chooses | Survives a restart | FTS5 | Opens in | 2000 inserts |
|---|---|---|---|---|---|
| Chrome 156 on macOS | `sharedIndexedDb` | yes | yes | 100-130 ms | 155 ms |
| Safari 26.5 on the iOS simulator | `sharedIndexedDb` | yes | yes | 155-215 ms | 680 ms |
| Chrome 113 on an Android 14 emulator | `unsafeIndexedDb` | yes | yes | 330-435 ms | 1 s |

  Firefox and a current Chrome on Android were not measured. With
  `unsafeIndexedDb`, two open tabs can overwrite each other's data.

## Decision

1. The ledger has three levels. A **transaction** says what happened, its
   **entries** move money on accounts with signed amounts in the currency of
   the account, and its **allocations** assign the amount to categories.

   | Kind | Entries | Allocations |
   |---|---|---|
   | Expense | one, negative | one or more, adding up to the amount |
   | Income | one, positive | one or more, adding up to the amount |
   | Transfer | two on different accounts, with opposite signs | none |
   | Adjustment | one | none |

2. A transfer between currencies keeps both amounts as they happened: the
   rate follows from them and is never recomputed. A fee is a separate expense.
3. A balance is the opening balance plus the entries that are not planned. It
   is computed, never stored.
4. Reports in the base currency convert at the rate of the date of each
   transaction. The capital converts at the latest rate.
5. Amounts are `int` minor units ([ADR 0003](0003-money-representation.md)),
   and rates are `Decimal` strings. `occurredOn` is a civil date, with an
   optional moment and offset beside it.
6. The schema is ready for sync from the start. Ids are UUIDv7 strings created
   on the device, every row has `createdAt`, `updatedAt` and `deletedAt`,
   deleting leaves a tombstone, there are no cascades, and every change also
   goes into a `changes` outbox.
7. One Drift schema lives in `packages/core/database`, in pure Dart, and the
   hosts open the connection: `drift_flutter` on phones and `WasmDatabase` on
   the web. Migrations go step by step with `drift_dev make-migrations`,
   committed snapshots and generated tests, and past steps never change.
8. On the web we take the storage that Drift chooses under Pages.
   `sqlite3.wasm` from the matching release of `sqlite3` is committed to
   `apps/web/web`, and the Jaspr build compiles the worker from
   `web/drift_worker.dart`. A worker cannot run as DDC modules, so `make
   run-web` serves the site in release mode too. With `unsafeIndexedDb`, a Web
   Lock keeps the app to one tab at a time: a second tab says so and takes over
   once the first one closes.
9. Search uses FTS5 on every platform.

## Options considered

| Option | Why not |
|---|---|
| Income and outcome fields in one row | transfers between currencies, fees and splits each become a special case |
| Full double entry with categories as accounts | a heavier interface for little gain in personal finance |
| Balances stored on accounts | a cached number that can drift apart from the entries |
| Integer ids | devices would collide when sync arrives |
| Reports at the latest rate | old reports would change with every new rate |
| A host with COOP and COEP, such as Cloudflare Pages | one more service; the storage above is enough for a demo, so we return to this if it stops being enough |
| `coi-serviceworker` to fake the headers | a reload on the first visit, and it can break resources from other origins |

## Consequences

- The first stage starts with `packages/core/database` and
  `packages/core/ledger`.
- Drift and the accounts add about 1.5 MB to the site, 580 KB compressed:
  730 KB of WASM, 380 KB of worker and 400 KB of deferred JavaScript. Only the
  pages of the app load it, so the first page stays light.
- A browser can evict the data of a site, so the web app needs the same file
  backup as the phones. Until then the accounts page says that the data stays
  in the browser, and warns when the browser keeps it only in memory.
- Chrome on macOS, Safari on iOS and Chrome 113 on Android store accounts and
  keep them. Firefox, where Drift prefers `opfsShared`, and a current Chrome on
  Android still have to be checked.
