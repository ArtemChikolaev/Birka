# ADR 0016 — A copy of the ledger in a file

**Status:** accepted 2026-11-02.

## Context

- The ledger lives only on the device ([ADR 0009](0009-data-model.md)). A
  person changes phones, a browser can evict the data of a site, and sync
  comes later.
- The screen «Данные» of the mockups saves a copy, restores one, exports the
  operations for a spreadsheet and deletes everything. Both hosts need it, and
  a copy from one host should open in the other.
- The mockups send files through the share sheet of the system.

## Decision

1. A copy is one JSON file, `birka-2026-11-02.birka`. It holds the mark
   `"format": "birka-copy"`, the `version` of the format, the moment `madeAt`,
   and every import, account, category and transaction with its entries and
   allocations inside it, with their ids and stamps. `LedgerCopy` in
   `packages/core/ledger` writes and reads it, the same code on both hosts.
   Version 2 added the imports, the import that brought an account, a
   category or a transaction, and allocations without a category
   ([ADR 0021](0021-statements.md)), version 3 the regular payments,
   version 4 what was done to their last times and version 5 their advances
   ([ADR 0023](0023-regular-payments.md)); files of the versions before
   still read.
2. Tombstones stay out of a copy: what a person deleted does not travel in a
   file that they may send somewhere. Exchange rates stay out because any
   device fetches them again, and settings because they belong to a device
   ([ADR 0011](0011-settings.md)).
3. A file becomes the ledger only after it passes the checks of `LedgerCopy`:
   the mark, a version this code reads, every field and name, the money of
   each account, the references, the two levels of categories, and the rules
   of each kind through the drafts of the ledger. A newer version asks for an
   update of the app. A copy that passes reads like one that the app wrote.
4. A restore and a wipe are the two writes that remove rows instead of leaving
   tombstones. One transaction empties the six tables of the ledger and the
   outbox, and a restore then writes the rows of the copy with their ids and
   stamps and puts an insert of each into the outbox. Before sync, a tombstone
   of a row that no other device has means nothing, and a wipe that leaves
   tombstones keeps the data that it promised to remove. Sync will need its
   own answer.
5. A person chooses where a file goes and where it comes from, in a window of
   the system: `file_picker` on the phones (Files on iOS, the documents of
   Android, a save panel on macOS) and the browser on the site. The share sheet
   of `share_plus` does not resolve in our workspace: 13.x needs `mime` 2,
   which `dds` under `jaspr_cli` does not allow, and 12.x needs `win32` 5,
   while `mason_logger` under it needs `win32` 6.
6. The export is CSV for Excel and Google Sheets, one row for each category of
   an expense or an income and for each account of a transfer, with signed
   amounts in the currency of the account. It is UTF-8 with a byte order mark,
   which Excel needs for Cyrillic, with the line ends of RFC 4180. The language
   of the app picks the marks: `;` between cells and `,` in amounts in
   Russian, as a Russian Excel expects, and `,` and `.` in English. Text that
   starts with `=`, `+`, `-` or `@` gets an apostrophe, so that a spreadsheet
   does not run it as a formula.
7. The moment of the last saved copy lives in the store of the settings under
   `last-copy-at`. It is when the person confirmed the save window, since the
   app cannot know where the file went, and a wipe keeps it: the copy is still
   out there. On the site it is when the download starts, because a page
   cannot see whether the person kept the file, such as when Safari on iPhone
   asks first.
8. The site puts a file into the downloads of the browser and takes one
   through its file chooser. The chooser asks for `.birka`, JSON and
   `application/octet-stream`: a computer then shows only copies, and Safari
   on iPhone, which knows no `.birka` and greys such files out, shows every
   file, as the app on a phone does. A chooser that closes without a file says
   so by its `cancel` event, which every browser has had since 2023. The focus
   that comes back to the window is no such sign: Chrome on Android hands
   over the chosen file seconds after it.

## Options considered

| Option | Why not |
|---|---|
| The SQLite file as the copy | the site keeps it inside IndexedDB, and a raw file cannot be checked before it replaces everything |
| Tombstones in the copy | the file would carry what a person deleted |
| A restore that merges with the ledger | rules for two versions of one row are the work of sync |
| A share sheet of our own over platform channels | native code for two platforms, while the save window already does the main job |
| A password on the copy | a password to lose; end-to-end encryption comes with sync |
| gzip | a year of operations is a few hundred kilobytes of JSON, and a plain file stays readable to its owner |

## Consequences

- The app needs iOS 14: `file_picker_darwin` 2.4 asks for it, and iOS 14 runs
  on the same phones as iOS 13. The macOS build gets the entitlement to read
  and write files that a person picks.
- The format changes only with a new version, and the reader keeps reading
  the old ones.
- A file larger than 64 MB is not a copy: a ledger of many years takes far
  less, and a video chosen by mistake is not read into memory.
- A browser older than the `cancel` event keeps the buttons of the data page
  waiting after its chooser closed without a file, until the page loads again.
- Demo data and the Help screen come in their own pull requests.
