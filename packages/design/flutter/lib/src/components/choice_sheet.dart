import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/components/glass_list.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// The last row of a choice sheet that does something other than choose,
/// such as «Новая категория»: its label, and what it does once the sheet
/// has closed.
typedef ChoiceAction = ({String label, VoidCallback onTap});

/// Asks for one of [choices] in a sheet from the bottom of the screen, with
/// [selected] marked and [subtitle], when there is one, under the title.
/// [subtitleOf] and [leadingOf] can give a choice a quieter line and a mark
/// before it, [accentOf] the color of the accent, and [action] adds a last
/// row in that color. The answer comes in a record, because `null` can be a
/// choice, and a closed sheet gives no record.
Future<(T,)?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> choices,
  required T selected,
  required String Function(T) labelOf,
  String? subtitle,
  String? Function(T)? subtitleOf,
  Widget? Function(T)? leadingOf,
  bool Function(T)? accentOf,
  ChoiceAction? action,
}) {
  final colors = BirkaColors.of(context);
  return showModalBottomSheet<(T,)>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: colors.background,
    builder: (context) => ChoiceSheet(
      title: title,
      subtitle: subtitle,
      children: [
        GlassListGroup(
          children: [
            for (final choice in choices)
              GlassListRow(
                title: labelOf(choice),
                accent: accentOf?.call(choice) ?? false,
                subtitle: subtitleOf?.call(choice),
                subtitleLines: 2,
                leading: leadingOf?.call(choice),
                trailing: choice == selected
                    ? BirkaIcon(BirkaGlyph.check, color: colors.accent)
                    : null,
                onTap: () => Navigator.of(context).pop((choice,)),
              ),
            if (action != null)
              GlassListRow(
                title: action.label,
                leading: BirkaIcon(
                  BirkaGlyph.plus,
                  size: 16,
                  color: colors.accent,
                ),
                accent: true,
                onTap: () {
                  Navigator.of(context).pop();
                  action.onTap();
                },
              ),
          ],
        ),
      ],
    ),
  );
}

/// What a sheet from the bottom of the screen holds: an optional title with
/// a quieter line under it, and the choices under them.
class ChoiceSheet extends StatelessWidget {
  /// Creates the content of a sheet.
  const ChoiceSheet({
    required this.children,
    this.title,
    this.subtitle,
    super.key,
  });

  /// The title.
  final String? title;

  /// The line under the title.
  final String? subtitle;

  /// The choices.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final subtitle = this.subtitle;
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(BirkaTokens.spaceLg),
        children: [
          if (title != null) ...[
            Text(title, style: styles.heading.copyWith(color: colors.text)),
            if (subtitle != null) ...[
              const SizedBox(height: BirkaTokens.spaceXxs),
              Text(
                subtitle,
                style: styles.caption.copyWith(color: colors.textMuted),
              ),
            ],
            const SizedBox(height: BirkaTokens.spaceMd),
          ],
          ...children,
        ],
      ),
    );
  }
}
