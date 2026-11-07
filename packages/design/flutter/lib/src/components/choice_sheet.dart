import 'dart:async';

import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/components/glass_list.dart';
import 'package:design_flutter/src/components/scroll_edge_fade.dart';
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
///
/// A sheet of many choices grows up to the status bar and no further, and
/// opens with [selected] in sight.
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
    useSafeArea: true,
    backgroundColor: colors.background,
    builder: (context) => ChoiceSheet(
      title: title,
      subtitle: subtitle,
      children: [
        GlassListGroup(
          children: [
            for (final choice in choices)
              _Shown(
                when: choice == selected,
                child: GlassListRow(
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
/// a quieter line under it, and the choices under them. The title stays in
/// place while the choices scroll under it, when they are many.
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BirkaTokens.spaceLg,
                BirkaTokens.spaceLg,
                BirkaTokens.spaceLg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: styles.heading.copyWith(color: colors.text),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: BirkaTokens.spaceXxs),
                    Text(
                      subtitle,
                      style: styles.caption.copyWith(color: colors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          Flexible(
            child: ScrollEdgeFade(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  BirkaTokens.spaceLg,
                  title == null ? BirkaTokens.spaceLg : BirkaTokens.spaceMd,
                  BirkaTokens.spaceLg,
                  BirkaTokens.spaceLg,
                ),
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row that brings itself into sight, [when] it is the choice in use, as
/// the sheet opens: the middle of a long list, for a choice down in it.
class _Shown extends StatefulWidget {
  const _Shown({required this.when, required this.child});

  final bool when;
  final Widget child;

  @override
  State<_Shown> createState() => _ShownState();
}

class _ShownState extends State<_Shown> {
  @override
  void initState() {
    super.initState();
    if (!widget.when) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(Scrollable.ensureVisible(context, alignment: 0.5));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
