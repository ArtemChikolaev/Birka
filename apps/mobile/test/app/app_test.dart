import 'dart:convert';

import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_flutter/accounts_flutter.dart';
import 'package:birka_mobile/app/app.dart';
import 'package:birka_mobile/app/more_page.dart';
import 'package:categories_common/categories_common.dart';
import 'package:categories_flutter/categories_flutter.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart'
    show
        AccountType,
        DayChange,
        Entry,
        Transaction,
        TransactionDraft,
        TransactionSource,
        TransactionStatus;
import 'package:money/money.dart';
import 'package:onboarding_common/onboarding_common.dart'
    show FirstAccount, OnboardingCubit, OnboardingRepository, ReadyCategory;
import 'package:onboarding_flutter/onboarding_flutter.dart';
import 'package:overview_common/overview_common.dart' hide Category;
import 'package:overview_flutter/overview_flutter.dart';
import 'package:reports_common/reports_common.dart'
    show ReportsCubit, ReportsRepository;
import 'package:reports_flutter/reports_flutter.dart';
import 'package:settings_common/settings_common.dart'
    show BaseCurrency, Settings, SettingsCubit, SettingsStore;
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/transactions_flutter.dart';

/// The settings in memory: the app under test needs no device.
final class _Settings implements SettingsStore {
  _Settings([Map<String, String>? values]) : values = values ?? {};

  final Map<String, String> values;

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// The accounts in memory: the app under test needs no database.
final class _NoAccounts implements AccountsRepository {
  @override
  Stream<List<AccountBalance>> watchAccounts() => Stream.value(const []);

  @override
  Stream<RateBook> watchRates() => Stream.value(const RateBook.empty());

  @override
  Stream<Currency?> watchBaseCurrency() => Stream.value(null);

  @override
  Future<AccountBalance?> account(String id) async => null;

  @override
  Future<void> add(AccountDraft draft) async {}

  @override
  Future<void> update(String id, AccountDraft draft) async {}

  @override
  Future<void> setArchived(String id, {required bool archived}) async {}
}

/// The ledger of a new device, in memory.
final class _NewDevice implements OnboardingRepository {
  @override
  Future<bool> hasAccounts() async => false;

  @override
  Future<void> save({
    required FirstAccount? account,
    required List<ReadyCategory> categories,
  }) async {}
}

final class _NoCategories implements CategoriesRepository {
  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) =>
      Stream.value(const []);

  @override
  Future<Category?> category(String id) async => null;

  @override
  Future<void> add(CategoryDraft draft) async {}

  @override
  Future<void> addAll(List<CategoryDraft> drafts) async {}

  @override
  Future<void> update(String id, CategoryDraft draft) async {}

  @override
  Future<void> setArchived(String id, {required bool archived}) async {}
}

final class _Transactions implements TransactionsRepository {
  List<Operation> operations = const [];

  @override
  Future<List<Account>> accounts() async => [
    for (final operation in operations) ?operation.account,
  ];

  @override
  Future<List<Category>> categories(CategoryKind kind) async => const [];

  @override
  Future<String?> lastAccountId() async => null;

  @override
  Future<void> record(TransactionDraft draft) async {}

  @override
  Stream<List<Operation>> watchOperations(CivilDate month) =>
      Stream.value(operations);

  @override
  Stream<Operation?> watchOperation(String id) => Stream.value(
    operations.where((operation) => operation.id == id).firstOrNull,
  );

  @override
  Future<List<CivilDate>> months() async => const [];

  @override
  Future<void> amend(String id, TransactionDraft draft) async {}

  @override
  Future<void> delete(String id) async {}
}

final class _Overview implements OverviewRepository {
  List<AccountBalance> accounts = const [];

  @override
  Stream<RateBook> watchRates() => Stream.value(const RateBook.empty());

  @override
  Stream<Currency?> watchBaseCurrency() => Stream.value(null);

  @override
  Stream<List<AccountBalance>> watchAccounts() => Stream.value(accounts);

  @override
  Stream<List<DayChange>> watchDayChanges({required CivilDate from}) =>
      Stream.value(const []);

  @override
  Stream<List<CategoryDayTotal>> watchSpending({
    required CivilDate from,
    required CivilDate to,
  }) => Stream.value(const []);
}

final class _NoReports implements ReportsRepository {
  @override
  Stream<Currency?> watchMainCurrency() => Stream.value(null);

  @override
  Stream<Currency?> watchBaseCurrency() => Stream.value(null);

  @override
  Stream<RateBook> watchRates() => Stream.value(const RateBook.empty());

  @override
  Stream<List<CategoryDayTotal>> watchDays(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  }) => Stream.value(const []);

  @override
  Future<List<CivilDate>> months() async => const [];
}

/// A coffee of today on an account of its own.
Operation _coffee() {
  const card = Account(
    id: 'card',
    name: 'Card',
    type: AccountType.debit,
    openingBalance: Money.zero(Currency.rub),
    includeInTotals: true,
    archived: false,
    sortOrder: 0,
  );
  return Operation(
    transaction: Transaction(
      id: 'coffee',
      kind: TransactionKind.expense,
      occurredOn: CivilDate.of(DateTime.now()),
      note: 'Coffee',
      status: TransactionStatus.cleared,
      source: TransactionSource.manual,
      entries: [Entry(accountId: card.id, amount: Money(-100, Currency.rub))],
      allocations: const [],
    ),
    account: card,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GetIt getIt;
  late _Transactions transactions;
  late _Overview overview;
  late _Settings settings;

  setUp(() {
    getIt = GetIt.asNewInstance();
    settings = _Settings();
    final AccountsRepository accounts = _NoAccounts();
    final CategoriesRepository categories = _NoCategories();
    transactions = _Transactions();
    overview = _Overview();
    getIt
      ..registerFactory(() => AccountsCubit(accounts))
      ..registerFactoryParam<AccountFormCubit, String?, void>(
        (accountId, _) => AccountFormCubit(accounts, accountId: accountId),
      )
      ..registerFactory(() => CategoriesCubit(categories))
      ..registerFactoryParam<CategoryFormCubit, String?, CategoryKind?>(
        (categoryId, kind) => CategoryFormCubit(
          categories,
          categoryId: categoryId,
          kind: kind ?? CategoryKind.expense,
        ),
      )
      ..registerFactory(() => OverviewCubit(overview))
      ..registerFactory(() => ReportsCubit(_NoReports()))
      ..registerSingleton<SettingsStore>(settings)
      ..registerFactory(
        () => SettingsCubit(
          settings,
          deviceLanguage: 'en',
          baseCurrency: BaseCurrency(null),
        ),
      )
      ..registerFactory(() => OperationsCubit(transactions))
      ..registerFactoryParam<OperationCubit, String, void>(
        (id, _) => OperationCubit(transactions, id),
      )
      ..registerFactoryParam<QuickAddCubit, QuickAddSource?, void>(
        (source, _) => QuickAddCubit(transactions, source: source),
      );
  });

  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('opens on the overview', (tester) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    expect(find.byType(OverviewPage), findsOneWidget);
    expect(find.text(t.accounts.emptyTitle), findsOneWidget);
  });

  group('a new device', () {
    setUp(() {
      getIt.registerFactory(
        () => OnboardingCubit(
          _NewDevice(),
          settings,
          deviceLanguage: 'en',
          baseCurrency: BaseCurrency(null),
        ),
      );
    });

    testWidgets('starts with the steps and ends on the overview', (
      tester,
    ) async {
      await tester.pumpWidget(BirkaApp(getIt: getIt, onboarding: true));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.byType(GlassNavBar), findsNothing);

      await tester.tap(find.text(t.onboarding.skip));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsNothing);
      expect(find.byType(OverviewPage), findsOneWidget);
      expect(find.byType(GlassNavBar), findsOneWidget);
      expect(Settings.readFrom(settings).onboarded, isTrue);
    });

    testWidgets('a language picked on the way keeps the steps open', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BirkaApp(getIt: getIt, onboarding: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('Все деньги —\nв одном месте'), findsOneWidget);
    });
  });

  testWidgets('dresses the app in the Birka theme', (tester) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(GlassNavBar)));
    expect(theme.extension<BirkaColors>(), same(BirkaColors.dark));
    expect(find.byType(AmbientBackground), findsOneWidget);
  });

  testWidgets('a tab opens its page, and the bar follows', (tester) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.reports));
    await tester.pumpAndSettle();

    expect(find.byType(ReportsPage), findsOneWidget);
    expect(find.text(t.app.reports), findsNWidgets(2));
    final bar = tester.widget<GlassNavBar>(find.byType(GlassNavBar));
    expect(bar.selectedIndex, 2);
  });

  testWidgets('the action opens quick add, and closing returns', (
    tester,
  ) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(t.app.newOperation));
    await tester.pumpAndSettle();
    expect(find.byType(QuickAddPage), findsOneWidget);
    expect(find.byType(GlassNavBar), findsNothing);

    await tester.tap(find.bySemanticsLabel(t.app.close));
    await tester.pumpAndSettle();
    expect(find.byType(QuickAddPage), findsNothing);
    expect(find.byType(GlassNavBar), findsOneWidget);
  });

  testWidgets('the overview leads to an account and to all of them', (
    tester,
  ) async {
    final coffee = _coffee();
    overview.accounts = [
      AccountBalance(coffee.account!, Money(100, Currency.rub)),
    ];
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CARD'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountFormPage), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(t.app.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.overview.allAccounts(n: 1).toUpperCase()));
    await tester.pumpAndSettle();
    expect(find.byType(AccountsPage), findsOneWidget);
  });

  testWidgets('without accounts the overview leads to adding one', (
    tester,
  ) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.accounts.add.toUpperCase()));
    await tester.pumpAndSettle();

    expect(find.byType(AccountFormPage), findsOneWidget);
  });

  testWidgets('the eye reaches the other tabs', (tester) async {
    transactions.operations = [_coffee()];
    overview.accounts = [
      AccountBalance(_coffee().account!, Money(100, Currency.rub)),
    ];
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(t.overview.hideAmounts));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.app.operations));
    await tester.pumpAndSettle();

    expect(find.text(formatMoney(Money(-100, Currency.rub))), findsNothing);
  });

  testWidgets('amounts start hidden when the settings say so', (tester) async {
    await const Settings(hideAmountsOnLaunch: true).writeTo(settings);
    transactions.operations = [_coffee()];
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.operations));
    await tester.pumpAndSettle();

    expect(find.text(formatMoney(Money(-100, Currency.rub))), findsNothing);
  });

  testWidgets('the setting waits for the next launch', (tester) async {
    transactions.operations = [_coffee()];
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.more));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.app.operations));
    await tester.pumpAndSettle();

    expect(Settings.readFrom(settings).hideAmountsOnLaunch, isTrue);
    expect(find.text(formatMoney(Money(-100, Currency.rub))), findsWidgets);
  });

  testWidgets('a new language reaches everything and keeps the tab', (
    tester,
  ) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.settings.language));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.settings.russian));
    await tester.pumpAndSettle();

    expect(LocaleSettings.currentLocale, AppLocale.ru);
    expect(Settings.readFrom(settings).language, AppLocale.ru);
    // The bar, and the page that stands open.
    expect(find.text('Обзор'), findsOneWidget);
    expect(find.text('Ещё'), findsNWidgets(2));
    expect(find.text('Язык'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    expect(find.byType(MorePage), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('ru'),
    );

    await tester.tap(find.text('Отчёты'));
    await tester.pumpAndSettle();

    expect(find.text('Отчёты'), findsNWidgets(2));
  });

  testWidgets('the operations tab tells when there are none', (tester) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.operations));
    await tester.pumpAndSettle();

    expect(find.text(t.transactions.noOperationsTitle), findsOneWidget);
  });

  testWidgets('a row leads to its card, and the card to the sheet', (
    tester,
  ) async {
    transactions.operations = [_coffee()];
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.operations));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();
    expect(find.byType(OperationPage), findsOneWidget);
    expect(find.byType(GlassNavBar), findsNothing);

    await tester.tap(find.text(t.transactions.edit));
    await tester.pumpAndSettle();
    expect(find.text(t.transactions.editOperation), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(t.app.close));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(t.transactions.repeat));
    await tester.pumpAndSettle();
    expect(find.text(t.app.newOperation), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(t.app.close));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(t.transactions.back));
    await tester.pumpAndSettle();
    expect(find.byType(OperationsPage), findsOneWidget);
    expect(find.byType(GlassNavBar), findsOneWidget);
  });

  testWidgets('accounts open from the more tab, over the bar', (tester) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.accounts.title));
    await tester.pumpAndSettle();

    expect(find.byType(AccountsPage), findsOneWidget);
    expect(find.byType(GlassNavBar), findsNothing);

    // The button of the header and the one of the empty list.
    await tester.tap(find.bySemanticsLabel(t.accounts.add).first);
    await tester.pumpAndSettle();
    expect(find.byType(AccountFormPage), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(t.app.close));
    await tester.pumpAndSettle();
    expect(find.byType(AccountsPage), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(t.accounts.back));
    await tester.pumpAndSettle();
    expect(find.byType(GlassNavBar), findsOneWidget);
  });

  testWidgets('categories open from the more tab with the kind on screen', (
    tester,
  ) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.categories.title));
    await tester.pumpAndSettle();
    expect(find.byType(CategoriesPage), findsOneWidget);

    await tester.tap(find.text(t.categories.income.toUpperCase()));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(t.categories.add));
    await tester.pumpAndSettle();

    final form = tester.element(find.byType(CategoryFormPage));
    expect(
      form.read<CategoryFormCubit>().state.kind,
      CategoryKind.income,
    );

    await tester.tap(find.bySemanticsLabel(t.app.close));
    await tester.pumpAndSettle();
    expect(find.byType(CategoriesPage), findsOneWidget);
  });

  test('bundles the fonts of the design system and their licenses', () async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json'))
            as List<Object?>;
    final families = [
      for (final font in manifest.cast<Map<String, Object?>>()) font['family'],
    ];
    expect(
      families,
      containsAll([
        for (final family in bundledFonts) 'packages/$fontPackage/$family',
      ]),
    );

    for (final family in bundledFonts) {
      final license = await rootBundle.loadString(
        'packages/$fontPackage/fonts/$family-OFL.txt',
      );
      expect(license, contains('SIL OPEN FONT LICENSE'));
    }
  });
}
