# ADR 0017 — How screens open and how things move

**Status:** accepted 2026-11-03.

## Context

- Every form of the app opened as a full screen dialog: on iOS it slid up from
  the bottom as one flat page. The form of an account repeats the card of the
  account in the same place, so for half a second two cards stood on the
  screen, one sliding over the other.
- The mockups of the canvas «Birka · Ночь» have a row «Переходы» with the
  approved way for each kind of screen, and a row «Анимации элементов» for
  the things inside a screen.
- The tokens already hold the durations 150, 220, 320 and 560 ms and the
  curves `standard` and `spring` ([ADR 0007](0007-design-tokens.md)).
- Flutter 3.38 has the sheet of iOS (`CupertinoSheetRoute`). Its routes do
  not look at Reduce Motion of iOS by themselves: that flag reaches
  `PlatformDispatcher.accessibilityFeatures.reduceMotion`, while the routes
  only shorten for `disableAnimations` of Android.

## Decision

1. A screen opens by its kind:

   | Kind | Example | How it opens |
   |---|---|---|
   | A tab | Обзор, Операции, Отчёты, Ещё | at once, as before |
   | Deeper | a row of a list → an account, an operation, Данные | the push of the platform, with the swipe back from the edge on iOS and predictive back on Android |
   | A card → its page | the card of an account on Обзор or Счета → the account | `BirkaZoomPage`: the card flies into its place on the page and grows, the page fades in and rises, the screen below fades and steps back, and the bar of the tabs goes down |
   | Something new | a new account, a category, «+» | `BirkaSheetPage`: the sheet of the system on iOS, a full screen dialog elsewhere |
   | A change of what is on screen | «Изменить» of an account | `BirkaFadePage`: it fades in over the page, the card stays where it is, `BirkaRise` lifts the fields and the button into place |

2. The sheet has no grabber: its cross closes it as well as a swipe down
   does. The sheet of Flutter 3.38 follows a swipe only where nothing scrolls,
   so a pull of its list past the top closes it too. The cross of a form is a
   bare icon in a target of 44 points (`GlassIconButton` with `glass: false`);
   the arrow back and the dots of a page keep their glass.
3. A card grows into its page only when the page opens from that card: the
   router opens an account as a `BirkaZoomPage` when the tap came from its
   card on Обзор or Счета, and as any deeper page when it came from a row.
   - The card is a `BirkaZoomSource`, and its place on the page is a
     `BirkaZoomTarget` with the same tag, the id of the account. A source
     flies only into a zoom page that opens over its own screen, so the list
     of accounts, which slides in with a card of the same account, leaves the
     card of Обзор where it is.
   - Flutter measures where a card lands in the first frame of the page, so
     the page keeps the place of the card empty at its size while it loads.
   - The card lays itself out by its height: the compact card of Обзор grows
     into the full card of the page instead of jumping from one to the other.
   - The page is a route of our own, so it has its own swipe back from the
     edge on iOS and its own predictive back on Android. Both play the
     opening backwards under the finger and let go with the numbers of a
     page of iOS.
   - It opens in `duration.zoom` (420 ms), the longest way anything travels,
     and closes in `duration.slow`. When the system asks for less motion,
     the card does not fly and the two screens only fade.
4. Durations and curves come from `BirkaMotion`, which reads the tokens:
   things move along `easing.standard` and fade along `easing.fade`, a gentle
   curve added for opacity, since the standard one does most of a fade in the
   first 70 ms and makes it snap. When the system asks for less motion (Reduce
   Motion on iOS, removed animations on Android), our own moves turn into
   fades: `BirkaMotion.reduced` checks both flags. The routes of the platform
   stay as they are.
5. Android turns on predictive back with
   `android:enableOnBackInvokedCallback` in the manifest, which Android 13 to
   15 need; on Android 16 the target SDK 36 turns it on anyway.
6. The swipe back from any place of a page, which iOS 26 added, waits: Flutter
   3.38 knows only the swipe from the edge, and the packages that add it fight
   with the swipe of the rows of operations.
7. Things inside a screen change with motion too (the row «Анимации
   элементов»): amounts roll, rows open and close, charts redraw, the month
   moves along time. They come in their own pull requests on top of
   `BirkaMotion`.
8. An amount rolls to a new value over `duration.roll`, as «Суммы» on the
   canvas shows: only the digits that change roll, up as it grows and down
   as it shrinks.
   - While it rolls, it takes the color of the news and turns back once it
     settles: green when things got better, red when they got worse. What is
     better depends on the amount (`AmountText.rise`): more is better for a
     balance, an income or a change, and worse for what was spent. The pill
     of a change only rolls, since its color already tells the news.
   - A change that comes while the amount is out of sight, under a sheet, on
     another tab or under another page, rolls once it shows again, so that
     the owner sees what a new operation did.
   - An amount does not roll the first time it shows, into another currency,
     nor while amounts are hidden; under Reduce Motion it changes at once and
     only its color comes and goes.
   - The chart of a period draws itself again when the period changes, as
     «График» on the canvas shows: the old line fades, the new one draws
     from the left over `duration.spring`, and its dot comes last with a
     little bounce (`BirkaLineChart.series`). The periods sit in a
     `ChipSwitch`, whose white pill slides to the picked one along
     `easing.spring`, and the caption of the period cross-fades.
   - Figures that change because the owner looks elsewhere, another month, a
     filter or a kind of report, start anew instead of rolling, and lists
     key their rows, so that no row rolls into the figure of another.
   - The parts of a ring move to their new shares over the same time: a new
     part grows from nothing in its place and one that goes shrinks to
     nothing (`RingSlice.id` keeps a part in its place). A row that comes to
     a short list opens and one that goes closes (`AnimatedColumn`), such as
     a new category of the month under the ring of Обзор.
   - When amounts get hidden, their digits blur away as the dots come, and
     come back sharp when they are shown.

9. A toast after an action, as «Уведомление» on the canvas shows, comes up
   from below with a little bounce over `duration.spring`, stays four
   seconds and goes a little down as it fades over `duration.base`; under
   Reduce Motion it only fades. It stands on the overlay of the navigator
   instead of in a `SnackBar` of Material, which clips what it holds and
   grows from its bottom edge, and it reads itself out to screen readers.
   A line that the action changes, such as the time of the last copy,
   cross-fades to the new one (`FadingText`).

10. The form of a new account moves as «Новый счёт: ввод и сохранение» on
    the canvas shows.
    - The card fades into a new art over `duration.slow` and its line into
      a new one (`FadingText`), so that a new type or look shows on the card
      at once. The board also gives a cash account the art of cash; the form
      keeps the art as a choice of its own, so a new type changes the line
      only.
    - The types and the currencies are a `ChipSwitch` that goes on to more
      lines (`wrap`), and its pill slides between the lines too.
    - Once saved, the button closes into a check mark: the label fades, the
      pill shrinks into a circle over `duration.slow`, the check comes in
      with a little bounce, and the form closes after the check has stood
      for half a second (`BirkaButton.done`). Under Reduce Motion the label
      only fades into the check.
    - The new account opens in the list once the sheet has gone. A
      `GlassListGroup` whose rows have keys opens and closes them as
      `AnimatedColumn` does. A change waits while a page lies over the page
      of the list or over the page that holds the tabs (`InSight`): the sheet
      of iOS leaves the page below it ticking, so tickers alone cannot tell.

11. The list of operations moves as «Операции: появление и удаление» on the
    canvas shows.
    - A new operation opens in its day once the sheet has gone, and one that
      is deleted closes, so that the rows below move to their places. A day
      opens with its first operation and closes with its last
      (`SliverAnimatedColumn`, which builds the days as they scroll into
      sight). The totals of the month and of the day roll in the color of
      the news (point 8).
    - A new month, filter or search changes the list at once.
    - Under Reduce Motion a row or a day that comes only fades in, and one
      that goes leaves at once, as in every `AnimatedColumn`.

## Consequences

- A new form picks its page by its kind, and the router says so in one place.
- A swipe down closes a sheet without asking, the same as the cross does
  today. A form that should keep what was typed needs its own guard later:
  the sheet of Flutter 3.38 pops without `PopScope`.
- The card of an account stays still between its page and its form only
  while both put it in the same place: under the header, `spaceLg` below it.
- A page that a card opens shows the place of the card from its first frame,
  before its data comes, or the card has nowhere to land.
