# ADR 0013 — The onboarding of a new device

**Status:** accepted 2026-11-01.

## Context

- A new device opens on an empty overview. The language and the base currency
  stand in More, and the ready categories in the list of categories, so a
  person meets them late or never.
- The [mockup](../design/README.md) shows the first of three steps: what Birka
  is and the language.
- The steps touch settings, accounts and categories, and features never depend
  on each other ([ADR 0006](0006-feature-first-packages.md)).

## Decision

1. `packages/features/onboarding` is a feature of its own that reads from the
   core, as the overview is. What it shares with other features moved there:
   `Settings`, `SettingsStore` and their labels to
   `packages/core/device_settings`, the ready categories to `ledger`, and their
   colors to `paletteColors` in `design_tokens`, because the core cannot depend
   on the design system.
2. There are three steps: what Birka is with the language and the base currency,
   the first account, and a ready set of categories, short with 7 or full
   with 15.
3. The language and the base currency apply at once, because the screens follow
   them. The account and the categories wait for the end and go in one
   transaction, so going back changes them and leaving adds nothing. The cubit
   stands above the router, because a new language brings a new router and what
   was typed has to survive it.
4. Skip ends the steps from anywhere. An account that the second step took
   stays, and what was typed on the second step and not taken goes.
5. `Settings.onboarded` marks a device that has finished or skipped. A device
   starts with the steps when it has no mark and holds no accounts, archived
   ones included, so an install from before the steps never sees them. A
   database that does not answer leaves the choice to the overview, which can
   say what is wrong.
6. The mark goes in before the save, so that running a failed save again cannot
   add the account twice. A failed save keeps the steps open.
7. The first account offers a debit card, cash and savings. A debt has its own
   sign and its own words, and the form of accounts has the rest.
8. The art of the first step is `packages/design/brand/welcome.svg`, rendered
   by `make icon-masters` and shipped as WebP to both kits, because `flutter_svg`
   draws no blur. A new token, `text.hero`, sets its headline.
9. On the site the steps stand on `overview/`, in place of the overview and
   without the tabs: its island opens the database anyway, so nothing reloads.
   A browser with no mark shows neither the header nor the tabs until the
   database has answered, so that the overview never flashes by. The other
   pages stay as they are, so a link to one of them still opens it.

## Options considered

| Option | Why not |
|---|---|
| Saving at each step | going back would have to change or delete what was saved, and leaving half way would leave half a setup |
| The hosts composing the steps from other features | the logic would live twice, in two hosts |
| The form of accounts as the second step | it belongs to another feature, and seven fields are a lot for the first minute |
| Only the mark, without a look at the accounts | an install from before the steps would see them |
| Only a look at the accounts, without a mark | whoever skipped would see the steps on every launch |
| The base currency only as the first account | a person who keeps rubles and counts in dollars would have to find it in More |
| Demo data on the second step | it needs a way out that removes it and nothing else, so it comes on its own |
| A page of its own on the site | the overview would have to open the database, leave for it and open it again, which costs a new person more than a second |
| Steps in the fragment of the address on the site | a link to a later step would open with nothing typed, and the way back on the page does the same job |

## Consequences

- A person who leaves half way starts over on the next launch, with the language
  and the base currency already picked. On the site the back button of the
  browser is such a way out.
- The second and third steps have no mockup yet. They use the components of the
  design system, and a mockup can replace them later.
