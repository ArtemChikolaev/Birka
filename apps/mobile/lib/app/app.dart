import 'package:birka_mobile/app/router.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

/// The root widget of the Flutter app.
///
/// Features plug into the router as they land (ADR 0006).
class BirkaApp extends StatefulWidget {
  /// Creates the app on the objects in [getIt].
  const BirkaApp({required this.getIt, super.key});

  /// Knows every implementation (ADR 0006).
  final GetIt getIt;

  @override
  State<BirkaApp> createState() => _BirkaAppState();
}

class _BirkaAppState extends State<BirkaApp> {
  late final GoRouter _router = buildRouter(widget.getIt);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Birka',
      theme: BirkaTheme.dark(),
      locale: Locale(LocaleSettings.currentLocale.languageCode),
      supportedLocales: [
        for (final locale in AppLocale.values) Locale(locale.languageCode),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
    );
  }
}
