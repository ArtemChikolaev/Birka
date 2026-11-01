import 'package:flutter/widgets.dart';

/// The art of the first screen: glass coins in three currencies on an orbit.
///
/// It says nothing that the words next to it do not, so screen readers skip
/// it.
class WelcomeArt extends StatelessWidget {
  /// Creates the art.
  const WelcomeArt({super.key});

  /// The width of the art at its full size. A wider screen leaves it there.
  static const double width = 390;

  /// The width of the art divided by its height.
  static const double aspectRatio = 1.3;

  /// How much of the height of a screen the art takes at most, so that a
  /// short phone still shows what comes after it.
  static const double _shareOfScreen = 0.34;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: MediaQuery.sizeOf(context).height * _shareOfScreen,
        ),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Image.asset(
            'images/welcome.webp',
            package: 'design_flutter',
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
