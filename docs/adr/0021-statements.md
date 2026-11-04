# ADR 0021 — Statements read on the device

**Status:** accepted 2026-11-04.

## Context

- Typing in a month of bank operations by hand takes too long, and Birka never
  asks for the password of a bank. A statement that a person downloads from
  their bank, or the export of another app, is the way in that keeps both.
- Banks export CSV in UTF-8, UTF-16 or Windows-1251, with commas, semicolons
  or tabs, or Excel workbooks. Some put the name of the bank and the period
  above the headers and a total under the operations; many also give PDF.
- The mockups of the import show a wizard on the site in six steps (the file,
  the bank, the columns with a live preview, the account, the duplicates and
  the result with an undo) and a short way on the phone.
- People who move from Zenmoney bring years of every account, category and
  transfer in one export.

## Decision

1. The import lives in `packages/features/import`. `import_common` reads a
   file into a `StatementTable`, finds its `StatementLayout` and reads its
   operations into a `Statement`; the hosts pick the file and draw the steps.
   Files are read on the device and never leave it.
2. `FileStatementReader` tells a file by its first bytes, not by its name: a
   ZIP archive is an Excel workbook, a PDF goes to the reader of PDF, and
   anything else is read as CSV. A workbook of Excel 97 (`.xls`), HTML and
   pictures are refused with a reason that the hosts can name. A file has at
   most 10 000 rows and 20 MB.
3. In CSV, a byte order mark tells UTF-8 or UTF-16, zero bytes tell UTF-16
   without a mark, valid UTF-8 stays UTF-8, and anything else is
   Windows-1251. The separator is whichever of `;`, `,`, tab and `|` splits
   the first lines into the same number of cells, unless a first line `sep=;`
   names it. Cells follow RFC 4180.
4. A workbook opens with `archive`, and `xml` reads its parts as a stream of
   events. The first sheet counts. Numbers stay exact decimals, and a number
   in the format of a date becomes a date, as Excel shows it.

   A PDF holds text where it stands on a page, not a table, so a PDF reads
   only when Birka knows its bank: for now Sberbank, which gives its clients
   no other file. A small reader of our own takes what such files are made
   of: the cross-reference as a table or a stream, objects in object streams,
   streams in Flate, composite fonts with their ToUnicode maps, and text
   placed by the matrices of text and graphics. It groups the text into lines
   by their height. The reading of Sberbank turns the two lines of each
   operation into a row of the columns of the statement, keeps a fee that an
   amount holds apart, and refuses a statement whose operations miss its
   totals (`UnreadableReason.incomplete`). A scan, an encrypted file and the
   PDF of another bank are refused.
5. A cell keeps what the file stores: text, a number or a date. Amounts stay
   `Decimal` until the account and its currency are known
   ([ADR 0003](0003-money-representation.md)). Text reads with one decimal
   mark at a time, and the other separator counts only between groups of
   three digits, so a wrong mark reads nothing rather than something wrong.
   Money spent is below zero, above zero, or without a sign while money
   received carries a plus, as the format says or the values show.
   Dates read day first or month first; a date that starts with four digits
   always starts with the year.
6. The known formats are data (`statementFormats`): Alfa-Bank, T-Bank,
   Sberbank, Zenmoney, Wise and Revolut, each with the headers it knows, its
   decimal mark, its order of dates, its sign and the statuses of operations
   that went through; the table of Sberbank comes from its PDF. They follow
   what is known of these exports and get checked against real files before
   people rely on them. T-Bank is checked against the CSV and the workbook
   of its web cabinet of November 2026, which list the accounts and cards
   picked there together, and Sberbank against a statement of a year; the
   others are not yet. Real files stay in `private/`; the tests use made-up
   ones.
7. A table matches a format when one of its first 30 rows has a date and
   money among the headers the format knows, and the format knows at least
   60% of the named headers of that row. The highest share wins, and a header
   that the format does not know tells its role by its words. Without a
   match, the row above the first operation is the row of headers, and the
   words of the headers or the values under them give the roles. The decimal
   mark and the order of dates come from the values when they tell, else from
   the format.
8. A row with a date and money is an operation. A row without anything like a
   date, such as a total or a title, is skipped. A row whose date does not
   read or does not exist, whose amount is missing, unreadable or zero, or
   whose status the format does not accept, is a `RowProblem` with the number
   of its row in the file.
9. An operation has up to two legs: the money that left an account and the
   money that reached one. A row of Zenmoney with both is a transfer. A fee
   on top of an amount stays apart from it. The account of a leg is named by
   its column, else by the currency of the row, else it is the one account of
   the file, and a balance and a card belong to the leg of their account. A
   bank that exports several accounts lists a transfer between them on each:
   the money that left one and the same money that reached the other, in one
   currency and with one description, on one day and at most two minutes
   apart, become one operation. A category that the person gave in the bank
   wins over the category of the bank. Each `SourceAccount` sums its
   operations and, when the file has balances, gives the balance before the
   first one and after the last.
10. An import is a row of its own in the ledger, `imports`: the name of the
    file, its format and the days of its first and last operation. The
    accounts, categories and transactions that an import brings name it in
    `importId`, and the whole import goes in through one `atomically`, so
    that a closed tab or app leaves none of it.
11. `undoImport` takes an import out in one write. Its transactions become
    tombstones, and so do the accounts and the categories it added that
    nothing else uses now, subcategories before their parents. What the
    person recorded and other imports stay, even when they moved money on an
    account of the import, and an account or a category that stays forgets
    the import. `watchImports` lists the imports that still have
    transactions, the latest first, for the list of past imports.
12. An imported expense or income can wait for its category: its allocation
    has the amount and no category ([ADR 0009](0009-data-model.md)). It
    counts in the balances, the overview and the reports from the start,
    where it stands as «Без категории» in a quiet color after the categories
    of its size. The forms of the app still save an operation only with a
    category.
13. A person chooses where each account of the file goes (an account of the
    ledger, a new account with the balance before the statement, or nowhere)
    and where each category of the bank goes for each kind of operation: a
    category of the ledger, a new one, inside another new one as the
    categories of Zenmoney are, or the inbox, where a category that nobody
    chose goes too. Fees have a choice of their own. `planImport` turns the
    rows into operations in the minor units of their accounts and names the
    rows that cannot go in: a currency other than that of the account, more
    digits than the currency has, a transfer in one currency with two
    amounts. A transfer between two accounts of the file that go into one
    account of the ledger stays out.
14. An operation looks like a transaction of the ledger when that one moves
    the same amount on the same account within a day of it. A name that
    shares a word makes it likelier, and a transaction that an import brought
    with the same day, amount and text is the operation itself imported
    again. Each transaction stands for one operation at most, so two equal
    operations of one file both go in. Copies stay out unless the person
    keeps them. The plan also gives the balance of each account on the day of
    the last operation after the import, to hold against the bank;
    `prepareImport` reads what the plan needs of the ledger.
15. `ImportRepository.write` puts a plan in through one `atomically`: the
    import, its new accounts and categories with parents before their
    subcategories, and its operations with what the bank wrote as their note
    and each fee as an expense of its own, telling its progress operation by
    operation. A year of Sberbank, 313 operations, goes in within 0.3 s on
    the VM.
16. `ImportCubit` walks the steps of the boards: the file, its format, its
    columns, its accounts, the copies and the result, and opens a step only
    when the ones before it allow. Birka chooses what it can: an open account
    of the currency with the digits of the card or the same name, else a new
    one named by the bank and the card, and a file that names no currency is
    in the base currency of the device; a category of the same name and kind,
    a subcategory for «Parent / Child», and new categories for Zenmoney. A
    category of a bank that plainly means a preset, such as «Супермаркеты» or
    «Такси» of T-Bank (`bankCategoryPresets`), goes into the category of that
    preset, found by its name or its icon; the others wait in the inbox. In
    two months of T-Bank this sorts 11 of its 24 categories and leaves 91 of
    283 operations in the inbox. A choice of the person stays while it fits the
    ledger, through another format or other roles of the columns. Each choice
    plans the import again and a late plan is dropped, so only the plan of the
    latest choices goes in, and the choices stay fixed while it does. Each
    host opens the window of files through `StatementFiles`.

## Options considered

| Option | Why not |
|---|---|
| A server that reads the file | the ledger never leaves the device, and there is no server |
| The `excel` or `spreadsheet_decoder` package | a new dependency for what `archive` and `xml`, already in the lock file, do here in a few hundred lines; both build the whole workbook as objects |
| Reading amounts by both marks at once | `1,234` would silently mean either 1234 or 1.234 |
| Telling the format by the name of the file | banks rename their exports, and people do too |
| A package for PDF: `pdfrx`, `syncfusion_flutter_pdf` or pdf.js on the site | native code or Flutter, so no pure-Dart core for both hosts, or a license of its own; the statements need only text, from a few kinds of file |
| Reading any PDF as a table by the positions of its text | each bank lays its statement out differently, and a wrong guess puts wrong amounts into the ledger |

## Consequences

- Before anything is written, the hosts can show the bank the file looks
  like, its columns with an example of each, the rows left out with their
  numbers and a summary for each account.
- The wizard on the site, the inbox and the sheet of the phone come next.
  They draw these steps and keep the choices of a format for its next file.
- A copy of the ledger is version 2 ([ADR 0016](0016-ledger-copy.md)): an app
  from before it says that the file comes from a newer version.
- Two banks with the same headers look like one. They read alike, so only the
  name that the hosts show is wrong, and the person can pick another format.
- `.xls` of Excel 97 and the PDF of other banks are refused for now; the
  hosts suggest saving the file as `.xlsx` or CSV, which most banks give.
  Another bank's PDF needs a reading of its own on the same reader.
