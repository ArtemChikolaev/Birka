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
   ZIP archive is an Excel workbook, anything else is read as CSV. PDF, a
   workbook of Excel 97 (`.xls`), HTML and pictures are refused with a reason
   that the hosts can name. A file has at most 10 000 rows and 20 MB.
3. In CSV, a byte order mark tells UTF-8 or UTF-16, zero bytes tell UTF-16
   without a mark, valid UTF-8 stays UTF-8, and anything else is
   Windows-1251. The separator is whichever of `;`, `,`, tab and `|` splits
   the first lines into the same number of cells, unless a first line `sep=;`
   names it. Cells follow RFC 4180.
4. A workbook opens with `archive`, and `xml` reads its parts as a stream of
   events. The first sheet counts. Numbers stay exact decimals, and a number
   in the format of a date becomes a date, as Excel shows it.
5. A cell keeps what the file stores: text, a number or a date. Amounts stay
   `Decimal` until the account and its currency are known
   ([ADR 0003](0003-money-representation.md)). Text reads with one decimal
   mark at a time, and the other separator counts only between groups of
   three digits, so a wrong mark reads nothing rather than something wrong.
   Dates read day first or month first; a date that starts with four digits
   always starts with the year.
6. The known formats are data (`statementFormats`): Alfa-Bank, T-Bank,
   Zenmoney, Wise and Revolut, each with the headers it knows, its decimal
   mark, its order of dates and the statuses of operations that went
   through. They follow what is known of these exports and get checked
   against real files before people rely on them. T-Bank is checked against
   the CSV of its web cabinet of November 2026, which lists the accounts and
   cards picked there together; the others are not yet. Real files stay in
   `private/`; the tests use made-up ones.
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

## Options considered

| Option | Why not |
|---|---|
| A server that reads the file | the ledger never leaves the device, and there is no server |
| The `excel` or `spreadsheet_decoder` package | a new dependency for what `archive` and `xml`, already in the lock file, do here in a few hundred lines; both build the whole workbook as objects |
| Reading amounts by both marks at once | `1,234` would silently mean either 1234 or 1.234 |
| Telling the format by the name of the file | banks rename their exports, and people do too |
| PDF statements | the text of a PDF holds no table; a later decision can add them |

## Consequences

- Before anything is written, the hosts can show the bank the file looks
  like, its columns with an example of each, the rows left out with their
  numbers and a summary for each account.
- Writing a statement into the ledger in one step, finding the operations
  that are already there and undoing an import come next, and extend this
  record.
- Two banks with the same headers look like one. They read alike, so only the
  name that the hosts show is wrong, and the person can pick another format.
- `.xls` of Excel 97 and PDF are refused for now; the hosts suggest saving the
  file as `.xlsx` or CSV.
