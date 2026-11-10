# ADR 0026 — The notices of the bell

**Status:** accepted 2026-11-07.

## Context

- Birka tells the person things at moments when the app may be closed: the
  reminders of the regular payments come as notifications of the phone
  ([ADR 0025](0025-reminders.md)), the payments that post themselves are
  posted when the app starts ([ADR 0023](0023-regular-payments.md)), and a
  statement marks the times it brings as done. A notification that was
  swiped away is gone, and what happened to its time is told nowhere.
- The owner asked for a bell on the overview with every message of Birka,
  the new ones on top, as in the apps of the banks, and a history of what
  became of each. The boards «Уведомления: колокольчик и лента» of the canvas
  draw the bell, the feed on the phone and on the site, and how the new ones
  move into the history.
- The history was first drawn as a chat: the message of Birka on the left
  and the answer under it on the right. A chat doubles the rows, reads as
  replies that the person typed, and would look like the support chat that
  comes with sync. The owner chose a list by days, as the operations are.
- `ScheduleLast` keeps only what was done to the last times of a payment
  (ADR 0023, point 14), so the history of every time cannot come from the
  ledger afterwards.

## Decision

1. A notice is a row of `notices` (version 8 of the schema): its source, when
   it came, when the person read it, and what it tells of. It belongs to the
   device, as the settings do: it goes into neither the outbox nor the copy
   of the ledger, and the device keeps it 90 days. A wipe and a restore
   empty it with the ledger, since its notices tell of the ledger that goes.
2. A notice of a payment tells of one time of one regular payment, at most
   once (`schedule_id`, `time_on`), with the name, the kind and the amount
   the payment had then, so that a later change of the payment leaves the
   history as it was.
   - It comes at the moment of the reminder of that time, on the day or the
     day before as the payment says, at the time of the reminders of the
     device (`remindersCame`). The notices take the reminders whatever the
     switches of the notifications and of the calendar say, and in the demo
     too: the bell is the app's own. A payment that never reminds gets no
     notice of a reminder.
   - `ReminderNotices` of `schedules_common` takes in the reminders that came
     when the app starts and comes back, after every change of the payments
     or of the time of the reminders, and at the moment of the next one
     while the app stays open, so a reminder of a closed app comes into the
     feed at its own moment on the next start.
   - A payment that Birka posts itself gets a notice of each time it posts,
     since nothing else tells the person of it.
3. What became of a time comes in the same write as the change of the
   payment, in `LedgerRepository`: posted, posted by Birka, skipped with the
   next time, or found in a statement. What the person does and what a
   statement brings only change the notices that are there, and what the
   person does reads them too: it is no news to them. An undone import
   takes back what its statement brought, and a payment whose next time moves,
   or that goes, drops its notices that still wait.
4. A notice of an import comes with the import and says what the ledger holds
   of it now: how many of its transactions stay and how many of those wait in
   the inbox without a category. After the undo it says that the import was
   undone.
5. The feed (`NotificationsCubit`) puts the new notices on top with a dot and
   the read ones below by days. A tap on a new notice reads it and opens its
   place: the regular payments for a time that came, the payment for a
   reminder of the day before, the inbox for an import whose operations
   wait. «Прочитать все» reads them all, and they close into the days of the
   history. Chips narrow the feed to one source while it has two.
6. A line of the history says what became of the notice in the color of the
   news: green when it went through, amber while it waits for the person,
   grey when it was skipped or undone. A new one says when its time comes,
   as the reminder did.
7. The bell stands in the header of the overview before the eye, a
   `GlassIconButton` with the count of the new notices on its corner. The
   count jumps when it grows and shrinks away at nought.
8. The site has the same bell, and the feed is a page of its own,
   `notifications/` (`notifications_jaspr`), in the column of a plain page,
   since the site has no side panels; «Прочитать все» stands in its header.
   A notice leads only where the site has a page: an import whose operations
   wait leads to the inbox, and a notice of a payment to the payments,
   `schedules/`, though the site makes none, having no reminders. A new one is read before the page leaves,
   so that the write does not race the next page. The site forgets the
   notices older than 90 days each time a page opens the database.

## Options considered

| Option | Why not |
|---|---|
| The history as a chat, as first drawn | it doubles the rows, reads as the person's replies, and would look like the support chat to come |
| Notices worked out from the ledger each time | the ledger keeps only the last times done of a payment, and a changed payment would rewrite its past |
| Notices of what the person did themselves | they are not news: the feed holds what Birka told and did |
| Notices in the copy of the ledger | they belong to the device, as its settings do, and a restore brings another ledger |
| Taking reminders only while the notifications are on | the feed is the app's own; a person who keeps the phone quiet still sees the bell |

## Consequences

- The site has no reminders, so its feed holds only the imports.
- A notice keeps the amount of its time, so a payment whose amount changes
  shows the old amount on its old notices.
- The notices of Birka about itself, such as what is new in a version, need
  a source of their own and the page «Что нового», which are not drawn yet.
