# Button

BirkaButton is the main action of a form or a sheet: a pill 56 px high and as wide as its column.

- **Primary** (no modifier): `color-accent` with `color-on-accent` text. One per screen: it saves, adds or goes on.
- **Quiet** (`birka-button--quiet`): `color-surface-raised` with `color-text`, for the second way out such as Cancel.
- **Danger** (`birka-button--danger`): a 16 % tint of `color-negative` with `color-negative` text, for deleting and undoing.
- **Compact** (`birka-button--compact`): 40 px high and as wide as its text, for an action inside a row.
- **Disabled**: half opacity, no pointer.

The consumer provides the label (`text-body-strong`) and what a press does, or an `href` for a link. In the app the main button of a form gets `done` once the form is saved and closes the form after its check mark.
