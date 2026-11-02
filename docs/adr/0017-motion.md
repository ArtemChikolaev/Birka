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
   | Deeper | a list → an account, an operation, Данные | the push of the platform, with the swipe back from the edge on iOS and predictive back on Android |
   | Something new | a new account, a category, «+» | `BirkaSheetPage`: the sheet of the system on iOS, a full screen dialog elsewhere |
   | A change of what is on screen | «Изменить» of an account | `BirkaFadePage`: it fades in over the page, the card stays where it is, `BirkaRise` lifts the fields and the button into place |

2. The sheet has no grabber: its cross closes it as well as a swipe down
   does. The sheet of Flutter 3.38 follows a swipe only where nothing scrolls,
   so a pull of its list past the top closes it too. The cross of a form is a
   bare icon in a target of 44 points (`GlassIconButton` with `glass: false`);
   the arrow back and the dots of a page keep their glass.
3. Durations and curves come from `BirkaMotion`, which reads the tokens:
   things move along `easing.standard` and fade along `easing.fade`, a gentle
   curve added for opacity, since the standard one does most of a fade in the
   first 70 ms and makes it snap. When the system asks for less motion (Reduce
   Motion on iOS, removed animations on Android), our own moves turn into
   fades: `BirkaMotion.reduced` checks both flags. The routes of the platform
   stay as they are.
4. Android turns on predictive back with
   `android:enableOnBackInvokedCallback` in the manifest, which Android 13 to
   15 need; on Android 16 the target SDK 36 turns it on anyway.
5. The swipe back from any place of a page, which iOS 26 added, waits: Flutter
   3.38 knows only the swipe from the edge, and the packages that add it fight
   with the swipe of the rows of operations.
6. Things inside a screen change with motion too (the row «Анимации
   элементов»): amounts roll, rows open and close, charts redraw, the month
   moves along time. They come in their own pull requests on top of
   `BirkaMotion`.

## Consequences

- A new form picks its page by its kind, and the router says so in one place.
- A swipe down closes a sheet without asking, the same as the cross does
  today. A form that should keep what was typed needs its own guard later:
  the sheet of Flutter 3.38 pops without `PopScope`.
- The card of an account stays still between its page and its form only
  while both put it in the same place: under the header, `spaceLg` below it.
