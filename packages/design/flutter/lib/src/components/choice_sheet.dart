import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/components/glass_list.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// Asks for one of [choices] in a sheet from the bottom of the screen, with
/// [selected] marked. The answer comes in a record, because `null` can be a
/// choice, and a closed sheet gives no record.
Future<(T,)?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> choices,
  required T selected,
  required String Function(T) labelOf,
}) {
  final colors = BirkaColors.of(context);
  return showModalBottomSheet<(T,)>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: colors.background,
    builder: (context) => ChoiceSheet(
      title: title,
      children: [
        GlassListGroup(
          children: [
            for (final choice in choices)
              GlassListRow(
                title: labelOf(choice),
                trailing: choice == selected
                    ? BirkaIcon(BirkaGlyph.check, color: colors.accent)
                    : null,
                onTap: () => Navigator.of(context).pop((choice,)),
              ),
          ],
        ),
      ],
    ),
  );
}

/// What a sheet from the bottom of the screen holds: an optional title and
/// the choices under it.
class ChoiceSheet extends StatelessWidget {
  /// Creates the content of a sheet.
  const ChoiceSheet({required this.children, this.title, super.key});

  /// The title.
  final String? title;

  /// The choices.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(BirkaTokens.spaceLg),
        children: [
          if (title != null) ...[
            Text(
              title,
              style: BirkaTextStyles.of(
                context,
              ).heading.copyWith(color: BirkaColors.of(context).text),
            ),
            const SizedBox(height: BirkaTokens.spaceMd),
          ],
          ...children,
        ],
      ),
    );
  }
}
