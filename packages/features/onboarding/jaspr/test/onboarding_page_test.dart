import 'package:design_jaspr/design_jaspr.dart';
import 'package:device_settings/device_settings.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:onboarding_common/onboarding_common.dart';
import 'package:onboarding_jaspr/onboarding_jaspr.dart';
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
  late OnboardingCubit cubit;
  late int finished;

  Future<void> pump(ComponentTester tester) async {
    cubit = OnboardingCubit(
      repository,
      store,
      deviceLanguage: 'en',
      baseCurrency: BaseCurrency(null),
    );
    tester.pumpComponent(
      BlocProvider.value(
        value: cubit,
        child: OnboardingPage(onFinished: () => finished++),
      ),
    );
    await tester.pump();
  }

  Future<void> tap(ComponentTester tester, String text) async {
    await tester.click(
      find.ancestor(of: find.text(text), matching: find.tag('button')).first,
    );
    await tester.pump();
    await tester.pump();
  }

  /// Fills in the name through the cubit, which the field calls, and moves on.
  Future<void> toCategories(ComponentTester tester) async {
    await pump(tester);
    await cubit.next();
    cubit.nameChanged('Card');
    await cubit.next();
    await tester.pump();
  }

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    setIsClientForTesting(true);
    store = _Store();
    repository = _Repository();
    finished = 0;
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testComponents('the first step says what Birka is', (tester) async {
    await pump(tester);

    expect(find.text('All your money\nin one place'), findsOneComponent);
    expect(find.byType(WelcomeArt), findsOneComponent);
    expect(find.text('English'), findsOneComponent);
    expect(find.text('Русский'), findsOneComponent);
    expect(find.text('Base currency'), findsOneComponent);
    expect(find.text('Get started'), findsOneComponent);
    expect(find.byType(GlassIconButton), findsNothing);
  });

  testComponents('a language turns the strings to it', (tester) async {
    await pump(tester);

    await tap(tester, 'Русский');

    expect(LocaleSettings.currentLocale, AppLocale.ru);
    expect(Settings.readFrom(store).language, AppLocale.ru);
  });

  testComponents('a base currency opens under its row', (tester) async {
    await pump(tester);
    expect(find.text('Euro'), findsNothing);

    await tap(tester, 'Base currency');
    expect(find.text('Euro'), findsOneComponent);

    await tap(tester, 'Euro');

    expect(find.text('Dollars'), findsNothing);
    expect(find.text('Euro'), findsOneComponent);
    expect(Settings.readFrom(store).baseCurrency, Currency.eur);
    expect(cubit.state.currency, Currency.eur);
  });

  testComponents('the button goes to the next step', (tester) async {
    await pump(tester);

    await cubit.next();
    await tester.pump();

    expect(find.text('Your first account'), findsOneComponent);
    expect(find.text('Next'), findsOneComponent);
    expect(find.byType(GlassIconButton), findsOneComponent);
  });

  testComponents('the card follows the account', (tester) async {
    await pump(tester);
    await cubit.next();

    cubit
      ..nameChanged('Cash box')
      ..currencyChanged(Currency.usd)
      ..amountChanged('12.50')
      ..typeChanged(AccountType.cash);
    await tester.pump();

    final card =
        find.byType(AccountCard).evaluate().single.component as AccountCard;
    expect(card.name, 'Cash box');
    expect(card.subtitle, 'Dollars · Cash');
    expect(card.amount, r'$12.50');
  });

  testComponents('says what is wrong with the account', (tester) async {
    await pump(tester);
    await cubit.next();

    await cubit.next();
    await tester.pump();

    expect(find.text('Give the account a name.'), findsOneComponent);
    expect(find.text('Your first account'), findsOneComponent);
  });

  testComponents('the sets show what they hold', (tester) async {
    await toCategories(tester);
    expect(find.text('7 categories'), findsOneComponent);
    expect(find.text('15 categories'), findsOneComponent);
    expect(find.text('Groceries'), findsOneComponent);
    expect(find.text('Travel'), findsNothing);

    await tap(tester, 'Full set');

    expect(find.text('Travel'), findsOneComponent);
  });

  testComponents('the end adds everything and opens the app', (tester) async {
    await toCategories(tester);

    await cubit.next();
    await tester.pump();

    expect(finished, 1);
    expect(repository.account?.name, 'Card');
    expect(repository.categories, hasLength(7));
    expect(Settings.readFrom(store).onboarded, isTrue);
  });

  testComponents('skipping opens the app with nothing added', (tester) async {
    await pump(tester);

    await tap(tester, 'Skip');

    expect(finished, 1);
    expect(repository.categories, isNull);
    expect(Settings.readFrom(store).onboarded, isTrue);
  });

  testComponents('skipping the last step keeps the account', (tester) async {
    await toCategories(tester);

    await tap(tester, 'Skip');

    expect(finished, 1);
    expect(repository.account?.name, 'Card');
    expect(repository.categories, isEmpty);
  });

  testComponents('the way back keeps the steps', (tester) async {
    await toCategories(tester);

    await tester.click(find.byType(GlassIconButton));
    await tester.pump();

    expect(find.text('Your first account'), findsOneComponent);
    final field =
        find.byType(input<String>).evaluate().first.component as input<String>;
    expect(field.value, 'Card');
  });

  testComponents('a failed save says so and can run again', (tester) async {
    await toCategories(tester);
    repository.failure = Exception('disk');

    await cubit.next();
    await tester.pump();
    expect(find.text('Could not save. Try again.'), findsOneComponent);
    expect(finished, 0);

    repository.failure = null;
    await cubit.next();
    await tester.pump();

    expect(finished, 1);
  });
}
