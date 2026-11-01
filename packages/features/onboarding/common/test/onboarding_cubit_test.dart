import 'package:device_settings/device_settings.dart';
import 'package:l10n/l10n.dart';
import 'package:onboarding_common/onboarding_common.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  late FakeSettingsStore store;
  late FakeOnboardingRepository repository;
  late BaseCurrency baseCurrency;
  late OnboardingCubit cubit;

  OnboardingCubit start() {
    final cubit = OnboardingCubit(
      repository,
      store,
      deviceLanguage: 'en',
      baseCurrency: baseCurrency,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  /// Fills in an account and comes to the last step.
  Future<void> toCategories() async {
    await cubit.next();
    cubit
      ..nameChanged('  Card ')
      ..amountChanged('1 250,50');
    await cubit.next();
  }

  bool onboarded() => Settings.readFrom(store).onboarded;

  setUp(() {
    store = FakeSettingsStore();
    repository = FakeOnboardingRepository();
    baseCurrency = BaseCurrency(null);
    cubit = start();
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('starts at the welcome with an account in the first currency', () {
    expect(cubit.state.step, OnboardingStep.welcome);
    expect(cubit.state.status, OnboardingStatus.editing);
    expect(cubit.state.baseCurrency, isNull);
    expect(cubit.state.currency, Currency.rub);
    expect(cubit.state.type, AccountType.debit);
    expect(cubit.state.categorySet, CategorySet.short);
  });

  group('the welcome', () {
    test('turns the app to a language and keeps it', () async {
      await cubit.languageChanged(AppLocale.ru);

      expect(LocaleSettings.currentLocale, AppLocale.ru);
      expect(Settings.readFrom(store).language, AppLocale.ru);
    });

    test('leaves the device in charge until a language is picked', () async {
      await cubit.languageChanged(AppLocale.en);

      expect(Settings.readFrom(store).language, isNull);
    });

    test('takes a base currency, for the totals and the account', () async {
      await cubit.baseCurrencyChanged(Currency.eur);

      expect(cubit.state.baseCurrency, Currency.eur);
      expect(cubit.state.currency, Currency.eur);
      expect(baseCurrency.value, Currency.eur);
      expect(Settings.readFrom(store).baseCurrency, Currency.eur);
    });

    test('can go back to following the first account', () async {
      await cubit.baseCurrencyChanged(Currency.eur);
      await cubit.baseCurrencyChanged(null);

      expect(cubit.state.baseCurrency, isNull);
      expect(cubit.state.currency, Currency.eur);
      expect(baseCurrency.value, isNull);
      expect(Settings.readFrom(store).baseCurrency, isNull);
    });

    test('starts on a base currency picked before', () {
      baseCurrency = BaseCurrency(Currency.usd);

      final later = start();

      expect(later.state.baseCurrency, Currency.usd);
      expect(later.state.currency, Currency.usd);
    });
  });

  group('the account', () {
    setUp(() => cubit.next());

    test('needs a name', () async {
      await cubit.next();

      expect(cubit.state.step, OnboardingStep.account);
      expect(cubit.state.errors, {OnboardingError.nameMissing});
    });

    test('takes a name of spaces for no name', () async {
      cubit.nameChanged('   ');

      await cubit.next();

      expect(cubit.state.errors, {OnboardingError.nameMissing});
    });

    test('needs an amount that is a number', () async {
      cubit
        ..nameChanged('Card')
        ..amountChanged('12,5,0');

      await cubit.next();

      expect(cubit.state.step, OnboardingStep.account);
      expect(cubit.state.errors, {OnboardingError.amountInvalid});
      expect(cubit.state.previewBalance, const Money.zero(Currency.rub));
    });

    test('forgets a complaint once the field changes', () async {
      cubit.amountChanged('abc');
      await cubit.next();

      cubit
        ..nameChanged('Card')
        ..amountChanged('12');

      expect(cubit.state.errors, isEmpty);
    });

    test('takes an amount in the currency of the account', () {
      cubit
        ..amountChanged('12.50')
        ..currencyChanged(Currency.usd);

      expect(cubit.state.balance, Money(1250, Currency.usd));
    });

    test('takes a kind of account', () {
      cubit.typeChanged(AccountType.cash);

      expect(cubit.state.type, AccountType.cash);
    });

    test('takes no amount for nothing on the account', () async {
      cubit.nameChanged('Card');

      await cubit.next();

      expect(cubit.state.step, OnboardingStep.categories);
      expect(cubit.state.errors, isEmpty);
    });

    test('adds nothing before the end', () async {
      cubit.nameChanged('Card');

      await cubit.next();

      expect(repository.saves, isEmpty);
      expect(onboarded(), isFalse);
    });
  });

  test('going back keeps what was typed', () async {
    await toCategories();

    cubit.back();
    expect(cubit.state.step, OnboardingStep.account);
    expect(cubit.state.name, '  Card ');

    cubit.back();
    expect(cubit.state.step, OnboardingStep.welcome);

    cubit.back();
    expect(cubit.state.step, OnboardingStep.welcome);
  });

  group('the end', () {
    test('adds the account and the short set in one go', () async {
      await toCategories();

      await cubit.next();

      expect(cubit.state.status, OnboardingStatus.finished);
      expect(repository.saves, hasLength(1));
      final saved = repository.saves.single;
      expect(saved.account?.name, 'Card');
      expect(saved.account?.type, AccountType.debit);
      expect(saved.account?.balance, Money(125050, Currency.rub));
      expect(saved.categories, hasLength(7));
      expect(onboarded(), isTrue);
    });

    test('adds every ready category with the full set', () async {
      await toCategories();
      cubit.categorySetChanged(CategorySet.full);

      await cubit.next();

      final categories = repository.saves.single.categories;
      expect(categories, hasLength(15));
      expect(categories.first.name, 'Groceries');
      expect(categories.first.kind, CategoryKind.expense);
      expect(categories.first.icon, 'cart');
      expect(categories.first.color, matches(RegExp(r'^#[0-9a-f]{6}$')));
      expect(
        categories.map((category) => category.kind),
        containsAll(CategoryKind.values),
      );
    });

    test('names the categories in the language of the user', () {
      LocaleSettings.setLocaleSync(AppLocale.ru);

      expect(CategorySet.short.categories.first.name, 'Продукты');
    });

    test('stays open when the save fails, and it can run again', () async {
      await toCategories();
      repository.failure = Exception('disk');

      await cubit.next();
      expect(cubit.state.status, OnboardingStatus.failed);
      expect(repository.saves, isEmpty);

      repository.failure = null;
      await cubit.next();

      expect(cubit.state.status, OnboardingStatus.finished);
      expect(repository.saves, hasLength(1));
    });

    test('a second tap saves nothing twice', () async {
      await toCategories();

      await Future.wait([cubit.next(), cubit.next()]);

      expect(repository.saves, hasLength(1));
    });

    test('going back after a failure lets the steps change', () async {
      await toCategories();
      repository.failure = Exception('disk');
      await cubit.next();

      cubit.back();

      expect(cubit.state.status, OnboardingStatus.editing);
    });
  });

  group('skipping', () {
    test('from the welcome adds nothing and opens the app', () async {
      await cubit.skip();

      expect(cubit.state.status, OnboardingStatus.finished);
      expect(repository.saves, isEmpty);
      expect(onboarded(), isTrue);
    });

    test('from the account leaves what was typed', () async {
      await cubit.next();
      cubit.nameChanged('Card');

      await cubit.skip();

      expect(repository.saves, isEmpty);
      expect(onboarded(), isTrue);
    });

    test('from the categories keeps the account', () async {
      await toCategories();

      await cubit.skip();

      final saved = repository.saves.single;
      expect(saved.account?.name, 'Card');
      expect(saved.categories, isEmpty);
    });

    test('keeps a language and a base currency that were picked', () async {
      await cubit.languageChanged(AppLocale.ru);
      await cubit.baseCurrencyChanged(Currency.usd);

      await cubit.skip();

      final settings = Settings.readFrom(store);
      expect(settings.language, AppLocale.ru);
      expect(settings.baseCurrency, Currency.usd);
      expect(settings.onboarded, isTrue);
    });
  });
}
