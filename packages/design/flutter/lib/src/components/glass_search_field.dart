import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/components/glass_surface.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A field of glass that searches as it is typed in, with a cross that clears
/// it.
class GlassSearchField extends StatelessWidget {
  /// Creates a field that edits [controller]. Screen readers read [label].
  const GlassSearchField({
    required this.label,
    required this.clearLabel,
    required this.controller,
    required this.onChanged,
    this.hint,
    super.key,
  });

  /// What the field is for, for screen readers.
  final String label;

  /// What the cross does, for screen readers.
  final String clearLabel;

  /// Holds the text.
  final TextEditingController controller;

  /// Called on every change, and when the cross clears the text.
  final ValueChanged<String> onChanged;

  /// What an empty field shows.
  final String? hint;

  void _clear() {
    controller.clear();
    onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final style = BirkaTextStyles.of(context).body;
    return GlassSurface(
      borderRadius: const BorderRadius.all(
        Radius.circular(BirkaTokens.radiusPill),
      ),
      padding: const EdgeInsets.symmetric(horizontal: BirkaTokens.spaceMd),
      child: SizedBox(
        height: BirkaTokens.sizeTouchTarget,
        child: Row(
          children: [
            BirkaIcon(BirkaGlyph.search, size: 20, color: colors.textMuted),
            const SizedBox(width: BirkaTokens.spaceSm),
            Expanded(
              child: Semantics(
                label: label,
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.sentences,
                  style: style.copyWith(color: colors.text),
                  cursorColor: colors.accent,
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: style.copyWith(color: colors.textSubtle),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                // Part of the field, so that the keyboard stays for a new word.
                return TextFieldTapRegion(
                  child: Semantics(
                    button: true,
                    label: clearLabel,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _clear,
                      child: Padding(
                        padding: const EdgeInsets.all(BirkaTokens.spaceXs),
                        child: BirkaIcon(
                          BirkaGlyph.close,
                          size: 18,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
