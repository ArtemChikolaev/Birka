import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

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
