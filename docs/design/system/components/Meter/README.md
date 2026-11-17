# Meter

BirkaMeter is a bar of how much of a whole is gone: the money of a day, the limit of a category. It fills up to its end and no further, and grows from nought in `duration-roll` as it shows.

Its track is `color-surface-raised`, `radius-pill`, 8 px high (6 px in a list). The fill takes the color the consumer passes:

- within a limit: `color-accent`;
- near its end, from 80 %: `color-palette-amber`;
- over: `color-negative`.

The note under it says the same in words («800 ₽ left · lasts until about 24 November», «1 400 ₽ over»), so the color is never alone. The categories keep their own colors on their glyph badges. A sum counted from another currency is shown with «≈».

The consumer provides the share (1 is the whole; more stays full), a label for screen readers («Cafés: 93 % of the limit spent») and the color. The meter knows nothing about money: the limits feature picks the color from where a limit stands.
