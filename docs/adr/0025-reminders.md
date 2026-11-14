# ADR 0025 — Reminders of the regular payments

**Status:** accepted 2026-11-07.

## Context

- A regular payment keeps whether to remind of its times: on the day, the
  day before or never (`ScheduleReminder`,
  [ADR 0023](0023-regular-payments.md)). Nothing reminded yet.
- Birka has no server for the data of a person, and the Go relay is not
  there yet. A push from a server would need the schedule of the payments
  on that server.
- The owner asked for two ways that the settings switch between: the
  notifications of the app, and events in the calendar of the phone, which
  remind even after the app is gone.
- The boards «Напоминания: Birka и календарь» of the canvas draw both ways,
  the sheets that ask for access, the line in the form of a payment, and how
  a reminder comes.

## Decision

1. Birka reminds in two ways, each with a switch of its own: with local
   notifications, which the phone keeps and shows on time with the app
   closed, and with the events of a calendar of its own, «Birka», which
   remind even after the app is gone. No server sends either.
2. The settings of the device hold the reminders (`ReminderSettings`): whether
   Birka sends notifications (`remind-notify`, off at first), whether it
   keeps the calendar (`remind-calendar`, off at first), at what time
   (`remind-time`, minutes after midnight, 9:00 at first), and whether they
   show the amounts (`remind-sums`, on at first). They live outside the
   database, as the other settings do ([ADR 0011](0011-settings.md)).
3. `planReminders` gives the reminders from the rules of the payments:
   - one for each time from the next one on, on its day or the day before;
   - the last day of a shorter month and both halves of a salary come as the
     rule gives them;
   - a time of today whose hour has passed is left out;
   - no more than 60, within 92 days, since iOS keeps at most 64.
4. A reminder says the name of the time and, with the amounts, the amount:
   «Аренда · 45 000 ₽», «Аванс · +60 000 ₽». The line under it says what a
   tap does: «Сегодня. Нажмите, чтобы провести или пропустить.», «Сегодня,
   проведётся само.» or «Завтра, 25 ноября. Нажмите, чтобы открыть платёж.»
   A tap on a reminder of the day opens the regular payments, where a time
   that waits is posted or skipped; a tap on one of the day before opens the
   payment. A payment deleted since then closes its form at once.
5. `ReminderScheduler` plans again after every change of the payments or the
   settings, after a new language and when the app comes back. A plan equal
   to the one the phone holds leaves it alone; another replaces every
   pending reminder of Birka, and the ones that came stay in the
   notification centre. The events of the calendar follow the same changes
   while the calendar is on. The days of the debts later joined the
   reminders of the phone, but not the calendar ([ADR 0029](0029-debts.md)).
6. The demo plans nothing: its payments are not the person's, and the phone
   keeps the reminders of the ledger of the device while the demo is on
   ([ADR 0019](0019-demo.md)).
7. `ReminderChannel` is the port to the phone, and
   `LocalReminderChannel` implements it with `flutter_local_notifications`
   22.3.3, `timezone` and `flutter_timezone`:
   - Android gets the boot receivers and core library desugaring, and keeps
     the classes of the plugin and of Gson from R8. It schedules without
     exact alarms (`inexactAllowWhileIdle`), so it needs no special
     permission and may show a reminder some minutes late.
   - iOS shows a reminder while Birka is open too.
8. «Ещё» gets the group «Напоминания» after «Безопасность».
   - «Уведомления от Birka» turns them on through a sheet that says how they
     come, with the nearest reminder as an example, and only then through the
     question of the phone.
   - «События в календаре» turns the calendar on through a sheet that says
     what Birka writes there, that a synced calendar takes the names and the
     amounts to iCloud or Google, and why the phone asks for full access.
     Turning it off asks first, then removes the calendar with its events.
   - A refusal of either says where to allow it, with «Открыть настройки»,
     which opens the settings of Birka on the phone.
   - «Время» and «Суммы в напоминаниях» show while either is on, and the
     caption under the group says what the ways that are on mean.
9. The form of a payment gets «Напомнить» with «В день», «За день» and «Не
   напоминать», and a line under it: «25 ноября в 9:00 · напомнит Birka»,
   «… · напомнит календарь «Birka»», «… · напомнят Birka и календарь», «Без
   напоминания», or «Напоминания выключены в «Ещё»» with «Включить
   напоминания», which turns the notifications on from the form. The line
   names the first reminder still to come: a time whose reminder has passed,
   such as one of today with «За день», gives way to the next time.
10. The calendar «Birka» holds one recurring event for each payment that
    reminds, and two for a salary in halves, the advance and the rest
    (`calendarReminders`).
    - An event starts at the time of the reminders on the day of each time,
      lasts 15 minutes and says what a reminder says. Its alarm rings at its
      start, or a day before for «За день».
    - Its rule repeats from the next time on, without an end: every week,
      every month on its day, or every year in its month. A shorter month
      gets its last day, as the rules of Birka do: the 31st is the last day
      of every month (`BYMONTHDAY=-1`), and the 29th or the 30th the last of
      the days from the 28th up to it (`BYMONTHDAY=28,29,30;BYSETPOS=-1`).
    - The calendar of iOS drops the days of a rule that the month of its
      first time lacks, so a monthly series of the 29th or the 30th whose
      next time falls on the last day of February starts in March, and that
      time in February is an event of its own.
11. `ReminderCalendar` is the port, and `DeviceReminderCalendar` implements it
    with `device_calendar_plus` 0.8.1:
    - it needs full access, since Birka changes and deletes its own events,
      and reads the events of no other calendar;
    - it makes the calendar in iCloud when the phone has it, and on the
      phone otherwise, in the accent of Birka;
    - the settings of the device keep the id of the calendar, the ids of its
      events and what they say, so that an equal plan leaves the calendar
      alone and another replaces its events;
    - a calendar the person deleted is made again on the next change, and a
      calendar «Birka» left by Birka before a reinstall is taken over and
      cleared;
    - iOS says why it asks in English and in Russian (`InfoPlist.strings`),
      and Android declares the calendar permissions.

## Options considered

| Option | Why not |
|---|---|
| Pushes from a server (FCM, APNs) | the server would have to know the payments; they wait for the support chat, which needs a server anyway |
| Repeating notifications instead of a plan | a repeating trigger keeps one day of a month, so the last day of a short month, the day before the 1st and an advance cannot be said by it |
| The events of the calendar alone | they need full access to the calendar on iOS and go to iCloud or Google when the calendar syncs; the owner wants both ways |
| Events in the default calendar of the person | they would mix with the person's own, and taking them away would mean telling them apart; a calendar of its own goes as a whole |
| One event for each time, as the notifications | a calendar that outlives the app would run out of them; a recurring event keeps reminding |
| Write-only access on iOS 17 | it reaches only the default calendar and cannot change or delete what it wrote |
| Exact alarms on Android | they need a permission of their own on Android 14, which a reminder at 9:00 does not need |

## Consequences

- A phone where Birka is not opened for three months runs out of planned
  reminders. Any return to the app plans further ones, and the events of the
  calendar cover a phone without the app.
- A time that is posted or skipped moves the next one, so the plan changes
  and the events are written again from the new next times; the calendar
  keeps no past times.
- With both ways on, a payment is reminded of twice.
- A change of the time zone moves nothing that is planned until the next
  plan, which comes with the next return to the app.
- The site has no reminders.
- The reminders that came also go into the notices of the bell, whatever
  the switches say ([ADR 0026](0026-notifications.md)).
