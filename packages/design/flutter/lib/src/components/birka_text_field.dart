import 'package:design_flutter/src/components/glass_surface.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
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
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.textStyle,
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

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final error = this.error;
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
        GlassSurface(
          borderRadius: const BorderRadius.all(
            Radius.circular(BirkaTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: BirkaTokens.spaceMd,
            vertical: BirkaTokens.spaceSm,
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            style: style.copyWith(color: colors.text),
            cursorColor: colors.accent,
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: style.copyWith(color: colors.textSubtle),
            ),
          ),
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
