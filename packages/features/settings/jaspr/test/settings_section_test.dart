import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';
import 'package:settings_jaspr/settings_jaspr.dart';

final class _Store implements SettingsStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  late _Store store;

  Future<void> pump(ComponentTester tester) async {
    tester.pumpComponent(
      BlocProvider(
        create: (_) => SettingsCubit(
          store,
          deviceLanguage: 'en',
          baseCurrency: BaseCurrency(null),
        ),
        child: const SettingsSection(),
      ),
    );
    await tester.pump();
  }

  Future<void> tap(ComponentTester tester, String text) async {
    await tester.click(
      find.ancestor(of: find.text(text), matching: find.tag('button')).first,
    );
    await tester.pump();
  }

  bool switchIsOn() =>
      (find.byType(BirkaSwitch).evaluate().single.component as BirkaSwitch)
          .value;

  setUp(() {
    store = _Store();
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('shows the language and the switch', (tester) async {
    await pump(tester);

    expect(find.text('Основное'), findsOneComponent);
    expect(find.text('Язык'), findsOneComponent);
    expect(find.text('Как на устройстве'), findsOneComponent);
    expect(find.text('Безопасность'), findsOneComponent);
    expect(find.text('Скрывать суммы'), findsOneComponent);
    expect(find.text('При запуске'), findsOneComponent);
    expect(switchIsOn(), isFalse);
  });

  testComponents('the languages open under their row', (tester) async {
    await pump(tester);

    await tap(tester, 'Язык');

    // The row itself, and the choice with its mark.
    expect(find.text('Как на устройстве'), findsNComponents(2));
    expect(find.text('English'), findsOneComponent);
    expect(find.text('Русский'), findsOneComponent);
    // The arrows of both rows, and the mark.
    expect(find.byType(BirkaIcon), findsNComponents(3));
  });

  testComponents('only one choice stands open', (tester) async {
    await pump(tester);

    await tap(tester, 'Язык');
    await tap(tester, 'Базовая валюта');

    expect(find.text('English'), findsNothing);
    expect(find.text('Рубли'), findsOneComponent);
  });

  testComponents('a picked base currency stays and the choice closes', (
    tester,
  ) async {
    await pump(tester);

    await tap(tester, 'Базовая валюта');
    await tap(tester, 'Евро');

    expect(Settings.readFrom(store).baseCurrency, Currency.eur);
    expect(find.text('Евро'), findsOneComponent);
    expect(find.text('Рубли'), findsNothing);
  });

  testComponents('the first account can be followed again', (tester) async {
    await const Settings(baseCurrency: Currency.eur).writeTo(store);
    await pump(tester);

    await tap(tester, 'Базовая валюта');
    await tap(tester, 'Первый счёт');

    expect(Settings.readFrom(store).baseCurrency, isNull);
  });

  testComponents('links to where the rates come from', (tester) async {
    await pump(tester);

    final link = find.tag('a').evaluate().single.component as DomComponent;

    expect(link.attributes?['href'], 'https://www.cbr-xml-daily.ru/');
    expect(find.text('Курсы ЦБ РФ в XML и JSON, API'), findsOneComponent);
  });

  testComponents('the row closes them too', (tester) async {
    await pump(tester);

    await tap(tester, 'Язык');
    await tap(tester, 'Язык');

    expect(find.text('English'), findsNothing);
  });

  testComponents('a picked language stays and the choice closes', (
    tester,
  ) async {
    await pump(tester);

    await tap(tester, 'Язык');
    await tap(tester, 'Русский');

    expect(Settings.readFrom(store).language, AppLocale.ru);
    expect(LocaleSettings.currentLocale, AppLocale.ru);
    expect(find.text('Русский'), findsOneComponent);
    expect(find.text('English'), findsNothing);
  });

  testComponents('the device can be picked back', (tester) async {
    await const Settings(language: AppLocale.ru).writeTo(store);
    await pump(tester);

    await tap(tester, 'Язык');
    await tap(tester, 'Как на устройстве');

    expect(Settings.readFrom(store).language, isNull);
    expect(LocaleSettings.currentLocale, AppLocale.en);
  });

  testComponents('the switch stays', (tester) async {
    await pump(tester);

    await tester.click(find.byType(BirkaSwitch));
    await tester.pump();

    expect(switchIsOn(), isTrue);
    expect(Settings.readFrom(store).hideAmountsOnLaunch, isTrue);
  });
}
