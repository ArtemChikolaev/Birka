# ADR 0033 — Monthly limits of categories

**Status:** accepted 2026-11-16.

## Context

- A person who counts money asks the same question every month: how much is
  left for cafés, for groceries, for going out, and will it last. «Можно
  тратить сегодня» (ADR 0023) answers it for the money of the days until the
  salary, but not for a category.
- Limits that count spending in several currencies are the third most voted
  request of Actual Budget, and neither Actual nor Monarch has them. The
  person of Birka pays from cards in rubles, euros and dollars.
- Birka has the rates of the Bank of Russia by day (ADR 0012), the start of
  the month in the settings (ADR 0024), regular payments (ADR 0023) and the
  notices of the bell (ADR 0026).
- The boards «Лимиты по категориям» of the canvas draw:
  - the part «Лимиты на ноябрь» at the bottom of the card «Траты в ноябре»
    of the overview, and an invitation when there are no limits;
  - the page «Лимиты»: what is left of each, the pace of one near its end,
    the categories without a limit;
  - the form of a limit, as a sheet;
  - limits offered from averages;
  - the line of quick add that says what an expense leaves;
  - a notice of the bell when a statement goes over a limit.

## Decision

1. A limit belongs to a top category of expenses and to a month: the month
   that the month start of the settings makes. Spending in subcategories
   counts against the limit of their parent. What a month leaves does not
   go into the next one.
2. A limit has an amount in a currency of its own. Spending in another
   currency counts at the rate of the day of each operation; a day without a
   rate takes the latest earlier one, and a currency that never had a rate
   is left out and the page says so. A sum counted from another currency is
   shown with «≈».
3. The limit lives in three columns of `categories` and whether Birka says
   so early in a fourth (schema 16), and in the copy (format 12). A category
   that becomes a subcategory leaves its limit; only an expense category at
   the top takes one, and a limit is above zero.
4. A limit is near its end from 80 % and over once the month took more. The
   bar is emerald, then amber, then coral, and its text says the same, so
   the color is never alone. The categories keep their colors on their
   icons.
5. A limit near its end says when it runs out at the pace of the days so
   far: «В таком темпе хватит до 21 ноября».
6. Birka offers limits from the average of the three full months before the
   current one, rounded up to 500 ₽, or to a round number about that much in
   another currency, such as 5 €. It checks a category whose every month
   spent and whose largest month is at most twice the smallest; it leaves
   unchecked a category that jumps, one that spent in some months only, and
   one that regular payments go to, and says why. Without a full month that
   spent it waits for one.
7. The form of a limit takes the sum from the average with one button.
   Another currency moves the sum at the rate of today and rounds it to the
   step of that currency, so 6 500 ₽ becomes 70 €, never 6 500 €.
8. Quick add says what an expense leaves of the limit of its category in the
   month of its day: «Кафе: останется 600 ₽ из 12 000 ₽», amber from 80 %,
   coral over the limit. A change of an operation says nothing, as the
   month already counts it.
9. The counting is in the package `rates`, where totals in a currency by day
   already are, so that quick add and the limits share it without one
   feature depending on another. The screens are the feature `limits`.
10. A notice of the bell comes when an operation that the person did not
    type crosses 80 % or the limit: an import of a statement or a regular
    payment. The notices table keeps the category and the share, one notice
    for each in a month. What the person types they see in quick add as
    they type it.

## Consequences

- The overview and the page show at a glance which category is running
  out, in any currency, on the device, with no server.
- Format 12 of the copy is new: an older Birka refuses a copy from this one,
  as with every format before.
- The rates come for the days of operations in a currency other than the
  base one. A limit in euros counts an expense in rubles at the latest rate
  before its day when that day has none.
- The site gets its boards and screens after the phone.

## Options considered

- **Limits in the base currency only:** simpler, but the trips of the person
  are in euros, and that is exactly what the others lack.
- **Envelopes that carry the rest over:** the habit of YNAB; it asks for a
  budget of every month and more care than a limit, so it is left for later.
- **A table of limits by month:** would keep the history of past limits, but
  a limit seldom changes, and the past months are counted from operations.
