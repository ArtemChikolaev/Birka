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

1. Birka reminds with local notifications: the phone keeps them and shows
   each on time, with the app closed. No server sends them. This change
   brings the notifications of the app; the events of the calendar come with
   a change of their own, under this ADR.
2. The settings of the device hold the reminders (`ReminderSettings`): whether
   Birka sends notifications (`remind-notify`, off at first), at what time
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
   notification centre.
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
   - A refusal says where to turn them on in the settings of the phone.
   - «Время» and «Суммы в напоминаниях» show while they are on.
9. The form of a payment gets «Напомнить» with «В день», «За день» and «Не
   напоминать», and a line under it: «25 ноября в 9:00 · напомнит Birka», «Без
   напоминания», or «Напоминания выключены в «Ещё»» with «Включить
   напоминания», which turns them on from the form. The line names the first
   reminder still to come: a time whose reminder has passed, such as one of
   today with «За день», gives way to the next time.

## Options considered

| Option | Why not |
|---|---|
| Pushes from a server (FCM, APNs) | the server would have to know the payments; they wait for the support chat, which needs a server anyway |
| Repeating notifications instead of a plan | a repeating trigger keeps one day of a month, so the last day of a short month, the day before the 1st and an advance cannot be said by it |
| The events of the calendar alone | they need full access to the calendar on iOS and go to iCloud or Google when the calendar syncs; the owner wants both ways |
| Exact alarms on Android | they need a permission of their own on Android 14, which a reminder at 9:00 does not need |

## Consequences

- A phone where Birka is not opened for three months runs out of planned
  reminders. Any return to the app plans further ones, and the events of the
  calendar will cover a phone without the app.
- A change of the time zone moves nothing that is planned until the next
  plan, which comes with the next return to the app.
- The site has no reminders.
