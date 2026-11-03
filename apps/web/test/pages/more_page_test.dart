import 'package:birka_web/pages/more_page.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';

final class _Store implements SettingsStore {
  @override
  String? read(String key) => null;

  @override
  Future<void> write(String key, String value) async {}
}

void main() {
  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  void pump(ComponentTester tester) => tester.pumpComponent(
    BlocProvider(
      create: (_) => SettingsCubit(
        _Store(),
        deviceLanguage: 'ru',
        baseCurrency: BaseCurrency(null),
      ),
      child: const MorePage(),
    ),
  );

  testComponents('leads to the accounts, the categories and the data', (
    tester,
  ) async {
    pump(tester);

    expect(find.text('Ещё'), findsOneComponent);
    expect(
      find
          .tag('a')
          .evaluate()
          .map(
            (element) =>
                (element.component as DomComponent).attributes?['href'],
          ),
      ['accounts/', 'categories/', 'data/', 'https://www.cbr-xml-daily.ru/'],
    );
    expect(
      find.descendant(of: find.tag('a'), matching: find.text('Счета')),
      findsOneComponent,
    );
    expect(
      find.descendant(of: find.tag('a'), matching: find.text('Категории')),
      findsOneComponent,
    );
    expect(
      find.descendant(of: find.tag('a'), matching: find.text('Данные')),
      findsOneComponent,
    );
  });

  testComponents('says that the import is yet to come', (tester) async {
    pump(tester);

    expect(find.text('Импорт'), findsOneComponent);
    expect(find.text('скоро'), findsOneComponent);
  });

  testComponents('holds the settings', (tester) async {
    pump(tester);

    expect(find.text('Язык'), findsOneComponent);
    expect(find.text('Скрывать суммы'), findsOneComponent);
  });
}
