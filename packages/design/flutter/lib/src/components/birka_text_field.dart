import 'package:design_flutter/src/components/glass_surface.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A field of glass with a label over it and an error under it.
class BirkaTextField extends StatelessWidget {
  /// Creates a field that edits [controller].
  const BirkaTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.textStyle,
    this.suffix,
    this.trailing,
    this.minLines,
    this.maxLines = 1,
    this.highlighted = false,
    super.key,
  });

  /// What the field is for.
  final String label;

  /// Holds the text.
  final TextEditingController controller;

  /// What an empty field shows.
  final String? hint;

  /// What is wrong with the text.
  final String? error;

  /// Called on every change.
  final ValueChanged<String>? onChanged;

  /// Called by the action key of the keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field takes the focus as soon as it appears.
  final bool autofocus;

  /// The keyboard of the field.
  final TextInputType? keyboardType;

  /// The action key of the keyboard.
  final TextInputAction? textInputAction;

  /// When the keyboard starts with a capital letter.
  final TextCapitalization textCapitalization;

  /// What the field lets through.
  final List<TextInputFormatter>? inputFormatters;

  /// A style in place of [BirkaTextStyles.body], such as the style of an
  /// amount.
  final TextStyle? textStyle;

  /// What stands at the end of the field, such as the sign of a currency.
  final String? suffix;

  /// What stands at the end of the field after [suffix], such as a chip that
  /// picks among numbers or fills the field from elsewhere.
  final Widget? trailing;

  /// The lines the field takes at least, for a text of several lines.
  final int? minLines;

  /// The lines the field grows to before it scrolls.
  final int maxLines;

  /// Whether the field glows in the accent for a moment, as when a value came
  /// into it from elsewhere, such as from a contact.
  final bool highlighted;

  static const _radius = BorderRadius.all(
    Radius.circular(BirkaTokens.radiusMd),
  );

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final error = this.error;
    final suffix = this.suffix;
    final style = textStyle ?? styles.body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: styles.caption.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        Stack(
          children: [
            GlassSurface(
              borderRadius: _radius,
              padding: const EdgeInsets.symmetric(
                horizontal: BirkaTokens.spaceMd,
                vertical: BirkaTokens.spaceSm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      autofocus: autofocus,
                      keyboardType: keyboardType,
                      textInputAction: textInputAction,
                      textCapitalization: textCapitalization,
                      inputFormatters: inputFormatters,
                      minLines: minLines,
                      maxLines: maxLines,
                      style: style.copyWith(color: colors.text),
                      cursorColor: colors.accent,
                      decoration: InputDecoration.collapsed(
                        hintText: hint,
                        hintStyle: style.copyWith(color: colors.textSubtle),
                      ),
                    ),
                  ),
                  if (suffix != null) ...[
                    const SizedBox(width: BirkaTokens.spaceXs),
                    Text(
                      suffix,
                      style: style.copyWith(color: colors.textSubtle),
                    ),
                  ],
                  if (trailing case final trailing?) ...[
                    const SizedBox(width: BirkaTokens.spaceXs),
                    trailing,
                  ],
                ],
              ),
            ),
            // The glow comes and goes over the surface, never in its way.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: highlighted ? 1 : 0,
                  duration: BirkaMotion.slow,
                  curve: BirkaMotion.fadeCurve,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: _radius,
                      color: colors.accent.withValues(alpha: 0.08),
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: BirkaTokens.spaceXxs),
          Text(
            error,
            style: styles.caption.copyWith(color: colors.negative),
          ),
        ],
      ],
    );
  }
}
