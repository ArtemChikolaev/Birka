import 'dart:async';

import 'package:birka_mobile/app/router.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';

/// The root widget of the Flutter app.
///
/// Features plug into the router as they land (ADR 0006).
class BirkaApp extends StatefulWidget {
  /// Creates the app on the objects in [getIt]. With [onboarding] it starts
  /// with the steps of a new device.
  const BirkaApp({required this.getIt, this.onboarding = false, super.key});

  /// Knows every implementation (ADR 0006).
  final GetIt getIt;

  /// Whether the app starts with the onboarding.
  final bool onboarding;

  @override
  State<BirkaApp> createState() => _BirkaAppState();
}

class _BirkaAppState extends State<BirkaApp> {
  late GoRouter _router = buildRouter(
    widget.getIt,
    initialLocation: widget.onboarding ? Paths.onboarding : Paths.overview,
  );
  late final ValueNotifier<bool> _hiddenAmounts = ValueNotifier(
    Settings.readFrom(widget.getIt<SettingsStore>()).hideAmountsOnLaunch,
  );
  late final StreamSubscription<AppLocale> _languages;

  @override
  void initState() {
    super.initState();
    _languages = LocaleSettings.getLocaleStream().listen(_onLanguageChanged);
  }

  /// `t` is not reactive (ADR 0010), so a new language takes new widgets. A
  /// new router brings them, on the page that stands open.
  void _onLanguageChanged(AppLocale _) {
    final previous = _router;
    setState(() {
      _router = buildRouter(
        widget.getIt,
        initialLocation: previous.state.uri.toString(),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  @override
  void dispose() {
    unawaited(_languages.cancel());
    _router.dispose();
    _hiddenAmounts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HiddenAmounts(
      notifier: _hiddenAmounts,
      child: MaterialApp.router(
        title: 'Birka',
        theme: BirkaTheme.dark(),
        locale: Locale(LocaleSettings.currentLocale.languageCode),
        supportedLocales: [
          for (final locale in AppLocale.values) Locale(locale.languageCode),
        ],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _router,
      ),
    );
  }
}
