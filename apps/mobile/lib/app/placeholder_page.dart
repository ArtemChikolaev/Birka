import 'package:birka_mobile/app/strings.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                Strings.comingSoon,
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

/// The sheet that adds an operation, until its feature lands.
class QuickAddPlaceholder extends StatelessWidget {
  /// Creates the sheet.
  const QuickAddPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(BirkaTokens.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(Strings.newOperation, style: styles.heading),
                    Semantics(
                      button: true,
                      label: Strings.close,
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: const SizedBox.square(
                          dimension: BirkaTokens.sizeTouchTarget,
                          child: Center(child: BirkaIcon(BirkaGlyph.close)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BirkaTokens.spaceMd),
                GlassSurface(
                  child: Text(
                    Strings.comingSoon,
                    style: styles.body.copyWith(
                      color: BirkaColors.of(context).textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
