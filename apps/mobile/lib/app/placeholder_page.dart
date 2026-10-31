import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// A tab until its feature lands.
class PlaceholderPage extends StatelessWidget {
  /// Creates a tab with [title].
  const PlaceholderPage({required this.title, super.key});

  /// The title of the tab.
  final String title;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(BirkaTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: styles.title),
            const SizedBox(height: BirkaTokens.spaceMd),
            GlassSurface(
              child: Text(
                t.app.comingSoon,
                style: styles.body.copyWith(
                  color: BirkaColors.of(context).textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
