import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';
import 'package:settings_flutter/settings_flutter.dart';

final class _Store implements SettingsStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  late _Store store;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: Scaffold(
          body: BlocProvider(
            create: (_) => SettingsCubit(
              store,
              deviceLanguage: 'en',
              baseCurrency: BaseCurrency(null),
            ),
            child: const SettingsSection(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String language) async {
    await tester.tap(find.text('Язык'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(language).last);
    await tester.pumpAndSettle();
  }

  setUp(() {
    store = _Store();
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('shows the language and the switch', (tester) async {
    await pump(tester);

    expect(find.text('ОСНОВНОЕ'), findsOneWidget);
    expect(find.text('Язык'), findsOneWidget);
    expect(find.text('Как на устройстве'), findsOneWidget);
    expect(find.text('БЕЗОПАСНОСТЬ'), findsOneWidget);
    expect(find.text('Скрывать суммы'), findsOneWidget);
    expect(find.text('При запуске'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('the sheet marks the language in use', (tester) async {
    await const Settings(language: AppLocale.ru).writeTo(store);
    await pump(tester);

    await tester.tap(find.text('Язык'));
    await tester.pumpAndSettle();

    // The row of the section, and the choice with its mark.
    expect(find.text('Русский'), findsNWidgets(2));
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Как на устройстве'), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Русский').last,
          matching: find.byType(GlassListRow),
        ),
        matching: find.byType(BirkaIcon),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a picked language stays', (tester) async {
    await pump(tester);

    await pick(tester, 'Русский');

    expect(Settings.readFrom(store).language, AppLocale.ru);
    expect(find.text('Русский'), findsOneWidget);
  });

  testWidgets('the device can be picked back', (tester) async {
    await const Settings(language: AppLocale.ru).writeTo(store);
    await pump(tester);

    await pick(tester, 'Как на устройстве');

    expect(Settings.readFrom(store).language, isNull);
    expect(LocaleSettings.currentLocale, AppLocale.en);
  });

  testWidgets('a picked base currency stays', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Базовая валюта'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Евро'));
    await tester.pumpAndSettle();

    expect(Settings.readFrom(store).baseCurrency, Currency.eur);
    expect(find.text('Евро'), findsOneWidget);
  });

  testWidgets('the first account can be followed again', (tester) async {
    await const Settings(baseCurrency: Currency.eur).writeTo(store);
    await pump(tester);

    await tester.tap(find.text('Базовая валюта'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Первый счёт'));
    await tester.pumpAndSettle();

    expect(Settings.readFrom(store).baseCurrency, isNull);
  });

  testWidgets('names where the rates come from', (tester) async {
    await pump(tester);

    expect(find.textContaining('cbr-xml-daily.ru'), findsOneWidget);
  });

  testWidgets('a closed sheet changes nothing', (tester) async {
    await const Settings(language: AppLocale.ru).writeTo(store);
    await pump(tester);

    await tester.tap(find.text('Язык'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(Settings.readFrom(store).language, AppLocale.ru);
  });

  testWidgets('the switch stays', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(Settings.readFrom(store).hideAmountsOnLaunch, isTrue);
  });

  testWidgets('fits a small phone in both languages', (tester) async {
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await pump(tester);

    expect(tester.takeException(), isNull);
  });
}
