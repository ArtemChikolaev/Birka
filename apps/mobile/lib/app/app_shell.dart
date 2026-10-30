import 'dart:math';

import 'package:birka_mobile/app/router.dart';
import 'package:birka_mobile/app/strings.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The frame of the app: the backdrop, the tabs and the floating navigation
/// bar above them.
class AppShell extends StatelessWidget {
  /// Creates the frame around [shell].
  const AppShell({required this.shell, super.key});

  /// The tabs, which keep their state while another one is open.
  final StatefulNavigationShell shell;

  /// The room that content leaves at the bottom for the navigation bar.
  static const double navBarClearance =
      BirkaTokens.sizeNavBar + BirkaTokens.spaceXl * 2;

  static const _destinations = [
    GlassNavDestination(glyph: BirkaGlyph.home, label: Strings.overview),
    GlassNavDestination(glyph: BirkaGlyph.list, label: Strings.operations),
    GlassNavDestination(glyph: BirkaGlyph.reports, label: Strings.reports),
    GlassNavDestination(glyph: BirkaGlyph.more, label: Strings.more),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      body: AmbientBackground(
        child: Stack(
          children: [
            Positioned.fill(child: shell),
            Positioned(
              left: BirkaTokens.spaceXxl,
              right: BirkaTokens.spaceXxl,
              bottom: max(BirkaTokens.spaceXl, bottomInset),
              child: GlassNavBar(
                destinations: _destinations,
                selectedIndex: shell.currentIndex,
                onSelected: (index) => shell.goBranch(
                  index,
                  initialLocation: index == shell.currentIndex,
                ),
                actionLabel: Strings.newOperation,
                onAction: () => context.push(Paths.quickAdd),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
