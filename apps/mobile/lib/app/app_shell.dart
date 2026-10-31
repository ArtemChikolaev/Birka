import 'dart:math';

import 'package:birka_mobile/app/router.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

/// The frame of the app: the backdrop, the tabs and the floating navigation
/// bar above them.
class AppShell extends StatelessWidget {
  /// Creates the frame around [shell].
  const AppShell({required this.shell, super.key});

  /// The tabs, which keep their state while another one is open.
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      // The keyboard covers the bar instead of pushing it over the content.
      resizeToAvoidBottomInset: false,
      body: AmbientBackground(
        child: Stack(
          children: [
            Positioned.fill(child: shell),
            Positioned(
              left: BirkaTokens.spaceXxl,
              right: BirkaTokens.spaceXxl,
              bottom: max(BirkaTokens.spaceXl, bottomInset),
              child: GlassNavBar(
                destinations: [
                  GlassNavDestination(
                    glyph: BirkaGlyph.home,
                    label: t.app.overview,
                  ),
                  GlassNavDestination(
                    glyph: BirkaGlyph.list,
                    label: t.app.operations,
                  ),
                  GlassNavDestination(
                    glyph: BirkaGlyph.reports,
                    label: t.app.reports,
                  ),
                  GlassNavDestination(
                    glyph: BirkaGlyph.more,
                    label: t.app.more,
                  ),
                ],
                selectedIndex: shell.currentIndex,
                onSelected: (index) => shell.goBranch(
                  index,
                  initialLocation: index == shell.currentIndex,
                ),
                actionLabel: t.app.newOperation,
                onAction: () => context.push(Paths.quickAdd),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
