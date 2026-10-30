/// Birka's design system for Flutter: the theme built from the design tokens,
/// the bundled Inter and Manrope fonts and the glass components (ADR 0007).
///
/// It re-exports the tokens, so a feature depends on this package alone.
library;

export 'package:design_tokens/design_tokens.dart';

export 'src/components/ambient_background.dart';
export 'src/components/amount_text.dart';
export 'src/components/birka_button.dart';
export 'src/components/birka_chip.dart';
export 'src/components/birka_icon.dart';
export 'src/components/birka_text_field.dart';
export 'src/components/card_art.dart';
export 'src/components/glass_icon_button.dart';
export 'src/components/glass_list.dart';
export 'src/components/glass_nav_bar.dart';
export 'src/components/glass_segmented.dart';
export 'src/components/glass_surface.dart';
export 'src/components/glyph_badge.dart';
export 'src/components/section_label.dart';
export 'src/fonts.dart';
export 'src/theme/birka_colors.dart';
export 'src/theme/birka_text_styles.dart';
export 'src/theme/birka_theme.dart';
