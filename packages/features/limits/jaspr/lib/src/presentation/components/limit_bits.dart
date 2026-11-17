import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:ledger/ledger.dart';
import 'package:rates/rates.dart';

/// The color of the bar of a limit in [state]: emerald while it lasts, amber
/// near its end and coral over it (ADR 0033).
String limitColor(LimitState state) => switch (state) {
  LimitState.ok => 'var(--color-accent)',
  LimitState.near => 'var(--color-palette-amber)',
  LimitState.over => 'var(--color-negative)',
};

/// The badge of [category] in its own color, or a quiet one without it.
GlyphBadge limitBadge(Category category, {int size = 36}) => GlyphBadge(
  glyph: BirkaGlyph.named(category.icon),
  color: category.color ?? 'var(--color-text-subtle)',
  size: size,
);

/// The styles that the parts of the limits share: the note of a limit in the
/// color of where it stands.
List<StyleRule> get limitNoteStyles => [
  css('.limit-note').styles(raw: {'color': 'var(--color-text-muted)'}),
  css('.limit-note--near').styles(
    raw: {'color': 'var(--color-palette-amber)'},
  ),
  css('.limit-note--over').styles(raw: {'color': 'var(--color-negative)'}),
];
