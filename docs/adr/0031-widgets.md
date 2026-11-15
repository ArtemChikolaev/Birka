# ADR 0031 — Widgets and quick actions

**Status:** accepted 2026-11-15.

## Context

- Recording an expense means opening the app, finding the plus and waiting
  for the sheet. Requests for widgets come up in 12 of 210 Russian reviews
  with requests that the research after the first version read, and the
  apps around Birka ship widgets for the home and the lock screen.
- The boards «Виджеты и быстрые действия» of the canvas draw:
  - «Сегодня», small and medium, with what can still be spent today, and
    «Запись», one button with no amounts;
  - the lock screen: a widget whose amount hides until Face ID, a round
    «+», and the control «Записать» at the bottom;
  - the actions of the icon: «Расход», «Доход», «Перевод», «Спросить»;
  - the page «Виджеты» with the switch «Суммы в виджетах»;
  - on Android «Сегодня» 4 × 2, «Запись» 2 × 1, the shortcuts of the icon
    and a button that adds the widget from the app.
- A widget runs in a process of its own (a WidgetKit extension, an
  `AppWidgetProvider`). It cannot run Dart, and opening the Drift database
  of the app from there would need a shared file and locking.

## Decision

1. The widgets never read the ledger. The app works out the figures of the
   day with the plan of [ADR 0023](0023-regular-payments.md) and hands them
   over as a snapshot (`WidgetSnapshot` in the core package `home_screen`):
   JSON of version 1, with the words already in the language of the app and
   the amounts already written. The platform keeps it where its widgets read
   it: an App Group on iOS, the preferences of the app on Android.
2. A snapshot holds today and tomorrow, as if nothing more is spent today,
   so that the widgets turn to the next day at midnight on their own. A day
   that is not there asks the person to open Birka: the app was not opened
   for two days, or the salary comes tomorrow and starts a new plan.
3. «Сегодня» repeats the card «Можно тратить сегодня» of the overview: what
   is left of the day, the share of the day and what was spent. Over the
   share it says so and tells the share of tomorrow. Without a salary to
   count until it shows what today took and asks for the payday.
4. The switch «Суммы в виджетах», a setting of the device that is on by
   default, hides the amounts behind dots before they leave the app. On the
   lock screen of iOS the amount stays hidden until Face ID.
5. What opens Birka from outside its window is one of six actions
   (`HomeAction`): the overview, the payday, a new expense, income or
   transfer, and a question. The platform keeps the action that launched
   Birka until the app asks for it, and sends the later ones as they come.
   An operation opens as a sheet over whatever stands open, once, and the
   steps of a new device stay.
6. The regular payments keep the widgets in step (`TodayWidgetFeed`), as
   they keep the reminders: the feed follows the plan, the switch and the
   language. A demo works out its figures for the page of the widgets but
   never hands them to the home screen: its money is not the person's.
7. The app answers the channel `birka/widgets` with a few lines of its own
   code on each platform, and no new package: `show`, `canPin`, `pin` and
   `takeAction` come from Dart, `open` and `pinned` go to it.
8. On iOS one widget extension holds the widgets and the control, and needs
   iOS 18, so that buttons inside the widgets and the control need no
   checks of the version; the app keeps iOS 14 and has no widgets below 18.
   On Android two `AppWidgetProvider`s draw `RemoteViews`, the shortcuts of
   the icon are static, and the page «Виджеты» adds «Сегодня» with
   `requestPinAppWidget`.

## Options considered

| Option | Why not |
|---|---|
| The widget reads the database | two processes on one SQLite file need a shared file and locking, and the rules of the plan would live in Swift and Kotlin too |
| The `home_widget` package | a dependency for some lines per platform, while the widgets are native code either way |
| Deep links of the router with a scheme of our own | a quick action on iOS starts the app with no address, and the router would get a second way in; asking the platform for the action works the same everywhere |
| Amounts always shown | the home and the lock screen are seen by others, and the person needs a way to hide them |
| Only the figures of today | after midnight the widget would show yesterday's money as today's until the app opens |

## Consequences

- The site has no widgets.
- The widgets show nothing until the app has opened once after the update.
- Left for later: the large size on iOS, the line above the clock, Siri
  telling how much is left, «Сегодня» 2 × 2 and a tile of the quick settings
  on Android, StandBy and the iPad.
- The App Group needs the capability in the Apple account to run on a
  phone; the simulator needs none.
