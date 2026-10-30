import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';

/// The root widget of the Flutter app.
///
/// For now it shows a placeholder in Birka's theme: features and the router
/// plug in here as they land (ADR 0006).
class BirkaApp extends StatelessWidget {
  /// Creates the app.
  const BirkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birka',
      theme: BirkaTheme.dark(),
      home: const _Placeholder(),
    );
  }
}

/// The name of the app on glass, until the first feature takes its place.
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: Center(
          child: GlassSurface(
            padding: const EdgeInsets.symmetric(
              horizontal: BirkaTokens.spaceXxl,
              vertical: BirkaTokens.spaceXl,
            ),
            child: Text('Birka', style: BirkaTextStyles.of(context).display),
          ),
        ),
      ),
    );
  }
}
