import 'package:design_flutter/design_flutter.dart';
import 'package:device_settings/device_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:onboarding_common/onboarding_common.dart';
import 'package:onboarding_flutter/onboarding_flutter.dart';
import 'package:rates/rates.dart';

final class _Store implements SettingsStore {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

final class _Repository implements OnboardingRepository {
  Exception? failure;
  FirstAccount? account;
  List<ReadyCategory>? categories;

  @override
  Future<bool> hasAccounts() async => false;

  @override
  Future<void> save({
    required FirstAccount? account,
    required List<ReadyCategory> categories,
  }) async {
    if (failure case final failure?) throw failure;
    this.account = account;
    this.categories = categories;
  }
}

void main() {
  late _Store store;
  late _Repository repository;
  late int finished;

  /// A tall phone, which builds the whole form of the account.
  void useTallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(402, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> pump(WidgetTester tester) async {
    final cubit = OnboardingCubit(
      repository,
      store,
      deviceLanguage: 'en',
      baseCurrency: BaseCurrency(null),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: HiddenAmounts(
          notifier: ValueNotifier(false),
          child: BlocProvider.value(
            value: cubit,
            child: OnboardingPage(onFinished: () => finished++),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> goForward(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel(label));
    await tester.pumpAndSettle();
  }

  Future<void> toCategories(WidgetTester tester) async {
    await pump(tester);
    await goForward(tester, 'Get started');
    await tester.enterText(find.byType(TextField).first, 'Card');
    await goForward(tester, 'Next');
  }

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    store = _Store();
    repository = _Repository();
    finished = 0;
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('goes from the welcome to an open app', (tester) async {
    useTallPhone(tester);
    await pump(tester);
    expect(find.text('All your money\nin one place'), findsOneWidget);
    expect(find.byType(WelcomeArt), findsOneWidget);

    await goForward(tester, 'Get started');
    expect(find.text('Your first account'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Card');
    await tester.enterText(find.byType(TextField).last, '1250,50');
    await tester.pump();
    await goForward(tester, 'Next');
    expect(find.text('Categories'), findsOneWidget);

    await goForward(tester, 'Done');

    expect(finished, 1);
    expect(repository.account?.name, 'Card');
    expect(repository.account?.balance, Money(125050, Currency.rub));
    expect(repository.categories, hasLength(7));
    expect(Settings.readFrom(store).onboarded, isTrue);
  });

  testWidgets('shows the first account as it is typed', (tester) async {
    useTallPhone(tester);
    await pump(tester);
    await goForward(tester, 'Get started');
    expect(find.text('Salary card'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'Cash box');
    await tester.pump();
    await tapText(tester, 'Cash');
    await tapText(tester, 'USD');

    expect(find.text('Cash box'), findsWidgets);
    expect(find.text('Dollars · Cash'), findsOneWidget);
  });

  testWidgets('says what is wrong with the account', (tester) async {
    useTallPhone(tester);
    await pump(tester);
    await goForward(tester, 'Get started');

    await goForward(tester, 'Next');
    expect(find.text('Give the account a name.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Card');
    await tester.enterText(find.byType(TextField).last, 'abc');
    await tester.pump();
    await goForward(tester, 'Next');

    expect(find.text('Your first account'), findsOneWidget);
    expect(find.textContaining('Enter an amount'), findsOneWidget);
  });

  testWidgets('the button in the corner goes back with the text', (
    tester,
  ) async {
    await toCategories(tester);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Your first account'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Card'), findsOneWidget);
  });

  testWidgets('the back of the system goes a step back', (tester) async {
    await toCategories(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Your first account'), findsOneWidget);
  });

  testWidgets('the welcome has no way back', (tester) async {
    await pump(tester);

    expect(find.bySemanticsLabel('Back'), findsNothing);
  });

  testWidgets('skipping opens the app with nothing added', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(finished, 1);
    expect(repository.categories, isNull);
    expect(Settings.readFrom(store).onboarded, isTrue);
  });

  testWidgets('skipping the last step keeps the account', (tester) async {
    await toCategories(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(finished, 1);
    expect(repository.account?.name, 'Card');
    expect(repository.categories, isEmpty);
  });

  testWidgets('the sets show what they hold', (tester) async {
    await toCategories(tester);
    expect(find.text('7 categories'), findsOneWidget);
    expect(find.text('15 categories'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Travel'), findsNothing);

    await tapText(tester, 'Full set');
    expect(find.text('Travel'), findsOneWidget);

    await goForward(tester, 'Done');

    expect(repository.categories, hasLength(15));
  });

  testWidgets('a failed save says so and can run again', (tester) async {
    await toCategories(tester);
    repository.failure = Exception('disk');

    await goForward(tester, 'Done');
    expect(find.text('Could not save. Try again.'), findsOneWidget);
    expect(finished, 0);

    repository.failure = null;
    await goForward(tester, 'Done');

    expect(finished, 1);
  });

  testWidgets('takes a base currency from a sheet', (tester) async {
    useTallPhone(tester);
    await pump(tester);

    await tapText(tester, 'Base currency');
    await tapText(tester, 'Euro');

    expect(find.text('Euro'), findsOneWidget);
    expect(Settings.readFrom(store).baseCurrency, Currency.eur);

    await goForward(tester, 'Get started');
    expect(find.text('Euro · Debit card'), findsOneWidget);
  });

  testWidgets('offers the languages and turns to one', (tester) async {
    useTallPhone(tester);
    await pump(tester);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);

    await tapText(tester, 'Русский');

    expect(LocaleSettings.currentLocale, AppLocale.ru);
    expect(Settings.readFrom(store).language, AppLocale.ru);
  });

  testWidgets('every step fits a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pump(tester);
    expect(tester.takeException(), isNull);
    await goForward(tester, 'Get started');
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField).first, 'Card');
    await goForward(tester, 'Next');
    expect(tester.takeException(), isNull);
  });
}
