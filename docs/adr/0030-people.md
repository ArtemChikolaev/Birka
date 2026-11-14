# ADR 0030 — The people of the debts

**Status:** accepted 2026-11-14.

## Context

- A debt was an account named after the other person
  ([ADR 0029](0029-debts.md)), and the form found the debt of a person by
  its name. Two different people of one name, a neighbour Иван and a
  colleague Иван, would fall into one debt.
- A person can owe and be owed at once: two debts, one of each side, which
  share nothing but the name.
- The owner asked to pick a person from the contacts of the phone. A contact
  often has a long or unclear name («Иванов Иван Петрович»), so Birka needs
  a short name of its own, and a way to say who the person is.
- The boards «Люди в долгах» of the canvas draw the phone and the site:
  a new person from the contacts, the hint about a namesake, the card with
  who the person is and «Напомнить», the message, and the terms.

## Decision

1. A person is a record of their own (`people`, version 14 of the schema).
   It holds the name that Birka shows, who they are (`about`, such as
   «коллега»), and a number to write to. Every debt points at its person
   (`accounts.person_id`), whichever way the money went, and wears their
   name. A new name of a person goes to all their debts at once.
2. Names may repeat. The chips of the form pick a person, and a name typed
   is someone new. When it is the name of someone there, the form says so
   and asks who the new one is. The chips of namesakes say who they are:
   «Иван · сосед».
3. Version 14 gives every debt a person: the debts of one name share one,
   which takes the id of the first of them. A copy of the ledger before
   version 10 does the same on the way in, and version 10 of the copy
   carries the people.
4. The number belongs to the person and stays on the device and in the
   copies that the person makes; the CSV of the operations leaves it out.
5. On the phone, someone new can come from the system window of the
   contacts (`CNContactPickerViewController` on iOS, `ACTION_PICK` of a
   phone number on Android). The window runs apart from Birka and gives it
   the contact picked alone, so Birka asks for no access to the address
   book. The first name becomes the name, and the person picks one of the
   numbers.
6. «Напомнить» on a debt owed to the person opens a ready text that the
   person may change, and hands it to an SMS to the number or to the window
   of sharing. Birka sends nothing itself. Both windows sit behind the port
   `PeoplePhone`, which the app answers over the channel `birka/people`
   with a few lines of its own code, and no new package.

## Options considered

| Option | Why not |
|---|---|
| The name, who they are and the number on each debt | the two debts of one person would each keep their own, and a new name would reach only one of them |
| Finding a person by the name typed, as before | a neighbour and a colleague of one name would share one debt |
| Keeping a link to the contact instead of its number | the ids of contacts differ between phones and platforms, and the site has none |
| A package that reads the address book | it asks for access to every contact, where the system window needs none |
| Sending the SMS from Birka | it needs a permission to send and a carrier; the person would not see what goes out |

## Consequences

- A debt still keeps the name on its account, so the operations, the
  notices and «Спросить» read it as before.
- A person whose debts are all deleted stays among the people, and no list
  of people is drawn yet: they show as the chips of the form.
