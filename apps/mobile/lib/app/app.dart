import 'dart:async';

import 'package:birka_mobile/app/router.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:onboarding_common/onboarding_common.dart' show OnboardingCubit;
import 'package:schedules_common/schedules_common.dart'
    show DebtReminderTap, PaymentReminderTap, ReminderChannel, ReminderTap;
import 'package:settings_common/settings_common.dart';

/// The root widget of the Flutter app.
///
/// Features plug into the router as they land (ADR 0006).
class BirkaApp extends StatefulWidget {
  /// Creates the app on the objects in [getIt]. With [onboarding] it starts
  /// with the steps of a new device.
  const BirkaApp({
    required this.getIt,
    this.onboarding = false,
    this.onDemoChanged,
    super.key,
  });

  /// Knows every implementation (ADR 0006).
  final GetIt getIt;

  /// Whether the app starts with the onboarding.
  final bool onboarding;

  /// Turns the demo on or off, which opens the other ledger (ADR 0019).
  final ValueChanged<bool>? onDemoChanged;

  @override
  State<BirkaApp> createState() => _BirkaAppState();
}

class _BirkaAppState extends State<BirkaApp> {
  /// The steps of a new device. A new language brings a new router, and what
  /// was typed on the way has to survive it.
  late final OnboardingCubit? _onboarding = widget.onboarding
      ? widget.getIt<OnboardingCubit>()
      : null;
  late GoRouter _router = buildRouter(
    widget.getIt,
    initialLocation: widget.onboarding ? Paths.onboarding : Paths.overview,
    onboarding: _onboarding,
    onDemoChanged: widget.onDemoChanged,
  );
  late final ValueNotifier<bool> _hiddenAmounts = ValueNotifier(
    Settings.readFrom(widget.getIt<SettingsStore>()).hideAmountsOnLaunch,
  );
  late final StreamSubscription<AppLocale> _languages;
  late final StreamSubscription<ReminderTap> _reminders;

  @override
  void initState() {
    super.initState();
    _languages = LocaleSettings.getLocaleStream().listen(_onLanguageChanged);
    // A tapped reminder of the day before opens its payment, one of the day
    // the regular payments, where it is posted (ADR 0025), and one of the day
    // of a debt its card (ADR 0029). The steps of a new device stay.
    _reminders = widget.getIt<ReminderChannel>().opened.listen((tap) {
      if (_onboarding != null) return;
      unawaited(
        _router.push(switch (tap) {
          PaymentReminderTap(:final scheduleId, early: true) => Paths.schedule(
            scheduleId,
          ),
          PaymentReminderTap() => Paths.schedules,
          DebtReminderTap(:final debtId) => Paths.debt(debtId),
        }),
      );
    });
  }

  /// `t` is not reactive (ADR 0010), so a new language takes new widgets. A
  /// new router brings them, on the page that stands open.
  void _onLanguageChanged(AppLocale _) {
    final previous = _router;
    setState(() {
      _router = buildRouter(
        widget.getIt,
        initialLocation: previous.state.uri.toString(),
        onboarding: _onboarding,
        onDemoChanged: widget.onDemoChanged,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  @override
  void dispose() {
    unawaited(_languages.cancel());
    unawaited(_reminders.cancel());
    unawaited(_onboarding?.close());
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
