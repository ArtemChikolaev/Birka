# Chip

BirkaChip is a pill 44 px high for a filter, a category, a tag or a month.

- At rest it sits on `color-surface-raised` in `color-text-secondary`.
- Selected (`birka-chip--selected`) it turns to `color-text` with `color-background` text: the one bright thing in a row of chips.
- Dashed (`birka-chip--dashed`) has no fill and a dashed `color-text-subtle` border, for something to add.
- Compact (`birka-chip--compact`) has `space-sm` padding.
- A count (`birka-chip__count`) shows how many items a filter holds.

The consumer provides the label, an optional leading icon (20 px) and what a press does. A row of options with one picked is a ChipSwitch in the app, and the chip of a month passes the month as `order`, so the content slides the right way.
