import 'package:flutter/material.dart';

/// The root widget of the Flutter app.
///
/// For now it shows a placeholder: features, the router and the theme from
/// the design system plug in here as they land (ADR 0006).
class BirkaApp extends StatelessWidget {
  /// Creates the app.
  const BirkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Birka',
      home: Scaffold(body: Center(child: Text('Birka'))),
    );
  }
}
