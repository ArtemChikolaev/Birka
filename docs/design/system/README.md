Birka is a local-first expense tracker for money across currencies, banks and countries. Its screens are dark and calm: black, glass and one emerald accent, so that the amounts are what a person sees first.

## Content fundamentals

- Write plainly, in short sentences, to the person as "you" only when you must; most text names things and states facts: «Limits for November», «800 ₽ left», «1 over».
- Sentence case for titles, buttons and rows: «Suggest from averages», «Set one by hand». Section labels are the one place for capitals, through `text-label`, never typed in capitals.
- Say what something does, not how it is built: «Spending in another currency counts at the rate of the Bank of Russia on the day of the operation».
- Every string exists in Russian and English. Amounts always go through the money formatter: «12 000 ₽», «2 480 €», a sum counted from another currency with «≈». Never build an amount from pieces of text.
- No emoji. Icons carry meaning only beside a word.
- Examples use made-up names and amounts; never real people, banks' customers or statements.

## Visual foundations

### Color

- The base is `color-background`, pure black, with the `color-ambient` glow in the top left and bottom right corners and on the left edge of every screen.
- Emerald `color-accent` is for accents only: the main button, the selected tab, links, income and progress that is fine. Text on it is `color-on-accent`.
- Text goes from `color-text` (titles, amounts, body) through `color-text-secondary` and `color-text-muted` to `color-text-subtle`, which is for hints only and never for text that must be read.
- `color-positive` is money in and changes for the better; `color-negative` is a fall, an overspend or deleting. Each always comes with a word or an arrow, never by color alone.
- Categories each take one of seven colors: `color-palette-green`, `amber`, `sky`, `violet`, `rose`, `orange`, `cyan`, shown on their glyph badges and in charts.
- Accounts are cards with abstract art that glows in one of the `color-art-*` colors.
- There is one theme, dark. The app follows no light mode.

### Type

- Manrope ExtraBold (`font-display`) for titles and amounts: `text-display` for the capital, `text-hero` for the amount of an operation, `text-title` for page titles, `text-heading` for cards, `text-amount` for amounts in rows.
- Inter (`font-text`) for everything else: `text-body`, `text-body-strong` for names and buttons, `text-caption` for notes and figures beside a name, `text-label` for section labels in spaced capitals, `text-tab` for the tab bar.
- Amounts use tabular figures, so that digits line up and a rolling figure does not jump.

### Surfaces

- Cards, panels and sheets are Liquid Glass (`Glass`): the backdrop blurred by `blur-glass` and made richer by `saturation-glass`, a faint white gradient from `color-glass-fill-top` to `color-glass-fill-bottom`, a `color-glass-border` hairline, a `color-glass-highlight` line along the top edge and `shadow-glass` under it.
- Fields and tracks are solid: `color-surface`, `color-surface-raised`, `color-surface-selected`.
- Rules between rows are `color-hairline`.

### Spacing, radii, sizes

- Spacing steps are `space-xxs` 4 through `space-xxl` 32. A phone screen keeps `space-md` at its sides; glass pads by `space-md`; sections of a page are `space-xl` apart.
- Radii grow with the size of the thing: `radius-xs` for tags, `radius-sm` for glyph badges, `radius-md` for options and fields, `radius-lg` for glass cards, `radius-xl` for account cards and sheets, `radius-pill` for buttons, chips, switches and meters.
- Anything a finger presses is at least `size-touch-target`, 44 px.

### Navigation

A floating glass bar centered at the bottom (`size-nav-bar`, `color-nav-fill`, `blur-nav`, `shadow-nav`), with a bubble under the selected tab (`color-nav-bubble`) and the add button in the middle. Tab labels are `text-tab` in `color-nav-label`.

### Motion

- Durations: `duration-fast` for presses and switches, `duration-base` for rows and chips, `duration-slow` for fades, `duration-roll` for digits that roll and rings that move, `duration-zoom` for a card that grows into its page, `duration-spring` for the tab bubble.
- Curves: `easing-standard` for movement, `easing-spring` for the bubble and switches, `easing-fade` for opacity.
- A screen opens by its kind: deeper pages push the way of the platform, a page grows out of the card that opens it, something new opens in a sheet, a change of what is on screen fades.
- Amounts that change roll to the new figure; a meter grows from nought.
- With reduced motion everything turns into fades or stops.

## Limits of categories

A category of expenses can have a monthly limit in any currency. The limits show at the bottom of the spending card of the overview («Limits for November»), on a page of their own, in a sheet to set one, and as a line in quick add that says what an expense leaves.

- Each limit is a row: the glyph badge, the name in `text-body-strong`, the figures in `text-caption` `color-text-secondary` («11 200 ₽ of 12 000 ₽»), a `Meter` 6 px high and a note in `text-caption`.
- The meter is `color-accent` within the limit, `color-palette-amber` from 80 %, `color-negative` over it. The note takes the same color and says the same in words: «2 900 ₽ left», «800 ₽ left · lasts until about 24 November», «1 400 ₽ over».
- Over first: the overview shows the three that need the person most, and a link row to all of them.
- Without limits the card invites: «Suggest from what you spend».

## Iconography

- Icons are Birka's own line set on a 24 × 24 grid: no fill, `currentColor` strokes 1.9–2.4 wide with round caps and joins. They live in `assets/Icons` and in the `BirkaGlyph` of both kits.
- Draw an icon at 24 px in rows, 20 px in chips, 16 px in link rows, 14 px in pills, 60 % of a glyph badge.
- An icon takes the color of its text, or of its category on a glyph badge.
- The app icon is a glass coin with a milled edge and the letter B in Manrope ExtraBold, on black with an emerald glow (`assets/Brand`).

## Mockups

The screens of the first version and of the import of statements are in `assets/Mockups`. They set the direction; when a mockup and the tokens disagree, the tokens win.
