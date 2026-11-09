import 'dart:async';
import 'dart:convert';

import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_flutter/accounts_flutter.dart';
import 'package:backup_common/backup_common.dart';
import 'package:backup_flutter/backup_flutter.dart';
import 'package:birka_mobile/app/app.dart';
import 'package:birka_mobile/app/app_version.dart';
import 'package:birka_mobile/app/more_page.dart';
import 'package:categories_common/categories_common.dart';
import 'package:categories_flutter/categories_flutter.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:help_common/help_common.dart';
import 'package:help_flutter/help_flutter.dart';
import 'package:import_common/import_common.dart'
    show ChosenStatement, StatementFiles;
import 'package:inbox_common/inbox_common.dart'
    show
        DismissedPairs,
        InboxCubit,
        InboxRepository,
        InboxSummaryCubit,
        TransferPair;
import 'package:inbox_flutter/inbox_flutter.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart'
    show
        Account,
        AccountBalance,
        AccountType,
        CivilDate,
        DayChange,
        Entry,
        LedgerImport,
        Notice,
        Schedule,
        Transaction,
        TransactionDraft,
        TransactionSource,
        TransactionStatus;
import 'package:money/money.dart';
import 'package:notifications_common/notifications_common.dart'
    show NotificationsCubit, NotificationsRepository, NotificationsSummaryCubit;
import 'package:notifications_flutter/notifications_flutter.dart'
    show NotificationsPage;
import 'package:onboarding_common/onboarding_common.dart'
    show FirstAccount, OnboardingCubit, OnboardingRepository, ReadyCategory;
import 'package:onboarding_flutter/onboarding_flutter.dart';
import 'package:overview_common/overview_common.dart' hide Category;
import 'package:overview_flutter/overview_flutter.dart';
import 'package:reports_common/reports_common.dart'
    show ReportsCubit, ReportsRepository;
import 'package:reports_flutter/reports_flutter.dart';
import 'package:schedules_common/schedules_common.dart'
    show
        CalendarReminder,
        OperationScheduleCubit,
        PaydaySettings,
        PlannedReminder,
        ReminderAccess,
        ReminderCalendar,
        ReminderChannel,
        ReminderNote,
        ReminderSettings,
        ReminderTap,
        RemindersCubit,
        ScheduleDraft,
        ScheduleFormCubit,
        SchedulesCubit,
        SchedulesRepository;
import 'package:schedules_flutter/schedules_flutter.dart'
    show ScheduleFormPage, SchedulesPage;
import 'package:settings_common/settings_common.dart'
    show BaseCurrency, MonthStart, Settings, SettingsCubit, SettingsStore;
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
final class _Accounts implements AccountsRepository {
  List<AccountBalance> balances = const [];

  @override
  Stream<List<AccountBalance>> watchAccounts() => Stream.value(balances);

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

/// Notifications that the phone never shows, and taps on them that a test
/// makes.
final class _NoReminders implements ReminderChannel {
  final taps = StreamController<ReminderTap>.broadcast();

  @override
  Future<ReminderAccess> access() async => ReminderAccess.unknown;

  @override
  Future<ReminderAccess> requestAccess() async => ReminderAccess.denied;

  @override
  Future<void> show(List<ReminderNote> notes) async {}

  @override
  Stream<ReminderTap> get opened => taps.stream;
}

/// A calendar that the phone never gives.
final class _NoCalendar implements ReminderCalendar {
  @override
  Future<ReminderAccess> access() async => ReminderAccess.unknown;

  @override
  Future<ReminderAccess> requestAccess() async => ReminderAccess.denied;

  @override
  Future<void> write(List<CalendarReminder> events) async {}

  @override
  Future<void> remove() async {}

  @override
  Future<void> openSettings() async {}
}

/// No regular payments and no accounts for them, so the card of the money of
/// the day stays away from the overview.
final class _NoSchedules implements SchedulesRepository {
  @override
  CivilDate today() => CivilDate(2026, 10, 31);

  @override
  Stream<List<Schedule>> watchSchedules() => Stream.value(const []);

  @override
  Stream<List<AccountBalance>> watchAccounts() => Stream.value(const []);

  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) =>
      Stream.value(const []);

  @override
  Stream<List<Transaction>> watchDay(CivilDate day) => Stream.value(const []);

  @override
  Stream<Transaction?> watchTransaction(String id) => Stream.value(null);

  @override
  Stream<Currency?> watchBaseCurrency() => Stream.value(null);

  @override
  Stream<int> watchMonthStart() => Stream.value(1);

  @override
  Stream<List<LedgerImport>> watchImports() => Stream.value(const []);

  @override
  Stream<PaydaySettings> watchSettings() =>
      Stream.value(const PaydaySettings());

  @override
  Future<void> saveSettings(PaydaySettings settings) async {}

  @override
  Stream<ReminderSettings> watchReminders() =>
      Stream.value(const ReminderSettings());

  @override
  Future<void> saveReminders(ReminderSettings settings) async {}

  @override
  Future<Schedule> add(ScheduleDraft draft) =>
      throw UnsupportedError('No regular payments here');

  @override
  Future<void> update(Schedule schedule) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<String> post(String id, {Money? amount, CivilDate? on}) async => id;

  @override
  Future<void> skip(String id) async {}

  @override
  Future<List<String>> postDue() async => const [];

  @override
  Future<void> noteReminders(List<PlannedReminder> reminders) async {}
}

/// A device that Birka told nothing yet.
final class _NoNotices implements NotificationsRepository {
  @override
  DateTime now() => DateTime(2026, 11, 25, 10);

  @override
  Stream<List<Notice>> watchNotices() => Stream.value(const []);

  @override
  Stream<int> watchNew() => Stream.value(0);

  @override
  Future<void> read([Iterable<String>? ids]) async {}

  @override
  Future<void> forgetOld() async {}
}

/// A ledger with nothing in the inbox.
final class _NoInbox implements InboxRepository {
  @override
  Stream<List<Transaction>> watchTransactions() => Stream.value(const []);

  @override
  Stream<List<Account>> watchAccounts() => Stream.value(const []);

  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) =>
      Stream.value(const []);

  @override
  Stream<RateBook> watchRates() => Stream.value(const RateBook.empty());

  @override
  Stream<List<LedgerImport>> watchImports() => Stream.value(const []);

  @override
  Future<void> categorize(List<(Transaction, String)> choices) async {}

  @override
  Future<String> makeTransfer(TransferPair pair) async => 'transfer';
}

final class _NoCategories implements CategoriesRepository {
  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) =>
      Stream.value(const []);

  @override
  Future<Category?> category(String id) async => null;

  @override
  Future<Category> add(CategoryDraft draft) async => Category(
    id: 'new',
    kind: draft.kind,
    name: draft.name,
    archived: false,
    sortOrder: 0,
  );

  @override
  Future<void> addAll(List<CategoryDraft> drafts) async {}

  @override
  Future<void> update(String id, CategoryDraft draft) async {}

  @override
  Future<void> setArchived(String id, {required bool archived}) async {}
}

final class _Transactions implements TransactionsRepository {
  List<Operation> operations = const [];
  AccountBalance? account;

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
  Stream<AccountBalance?> watchAccount(String id) => Stream.value(account);

  @override
  Stream<List<DayChange>> watchAccountChanges(
    String id, {
    required CivilDate from,
  }) => Stream.value(const []);

  @override
  Stream<List<Operation>> watchAccountOperations(String id) =>
      Stream.value(operations);

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
  int monthStart() => 1;

  @override
  Stream<int> watchMonthStart() => Stream.value(1);

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

final class _EmptyLedger implements BackupRepository {
  @override
  Stream<LedgerCounts> watchCounts() => Stream.value(
    const LedgerCounts(accounts: 0, categories: 0, transactions: 0),
  );

  @override
  Future<LedgerCopy> copy() => throw UnimplementedError();

  @override
  Future<void> restore(LedgerCopy copy) => throw UnimplementedError();

  @override
  Future<void> wipe() async {}

  @override
  Future<OperationsExport> operations() => throw UnimplementedError();
}

final class _NoFiles implements BackupFiles {
  @override
  Future<bool> save({
    required String name,
    required String type,
    required Uint8List bytes,
  }) async => false;

  @override
  Future<ChosenFile?> open() async => null;
}

/// The window of statements, closed each time it opens.
final class _Statements implements StatementFiles {
  int opened = 0;

  @override
  Future<ChosenStatement?> choose() async {
    opened++;
    return null;
  }
}

final class _NoWayOut implements HelpLinks {
  @override
  Future<bool> mail(Uri letter) async => false;

  @override
  Future<bool> open(Uri page) async => false;

  @override
  Future<void> copy(String text) async {}
}

/// Ways out that keep the pages they were asked to open.
final class _Links implements HelpLinks {
  final pages = <Uri>[];
  bool opens = true;

  @override
  Future<bool> mail(Uri letter) async => false;

  @override
  Future<bool> open(Uri page) async {
    pages.add(page);
    return opens;
  }

  @override
  Future<void> copy(String text) async {}
}

final class _NoReports implements ReportsRepository {
  @override
  int monthStart() => 1;

  @override
  Stream<int> watchMonthStart() => Stream.value(1);

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
  Future<List<CivilDate>> months({int start = 1}) async => const [];
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

/// The page that shows the account.
Page<Object?> pageOf(WidgetTester tester) =>
    ModalRoute.of(tester.element(find.byType(AccountPage)))!.settings
        as Page<Object?>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GetIt getIt;
  late _Accounts accounts;
  late _Transactions transactions;
  late _Overview overview;
  late _Settings settings;
  late _Links links;
  late _Statements statements;
  late _NoReminders reminders;
  late List<String?> forms;

  setUp(() {
    getIt = GetIt.asNewInstance();
    settings = _Settings();
    links = _Links();
    statements = _Statements();
    reminders = _NoReminders();
    forms = [];
    accounts = _Accounts();
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
      ..registerFactory(
        () => InboxSummaryCubit(_NoInbox(), DismissedPairs(settings)),
      )
      ..registerFactory(() => InboxCubit(_NoInbox(), DismissedPairs(settings)))
      ..registerFactory(() => NotificationsSummaryCubit(_NoNotices()))
      ..registerFactory(() => NotificationsCubit(_NoNotices()))
      ..registerFactory(() => ReportsCubit(_NoReports()))
      ..registerFactory(() => SchedulesCubit(_NoSchedules()))
      ..registerSingleton<ReminderChannel>(reminders)
      ..registerFactory(
        () => RemindersCubit(_NoSchedules(), reminders, _NoCalendar()),
      )
      ..registerFactoryParam<
        ScheduleFormCubit,
        String?,
        ({bool salary, String? from})?
      >((id, start) {
        forms.add(id);
        return ScheduleFormCubit(
          _NoSchedules(),
          id: id,
          salary: start?.salary ?? false,
          from: start?.from,
        );
      })
      ..registerFactoryParam<OperationScheduleCubit, String, void>(
        (id, _) => OperationScheduleCubit(_NoSchedules(), id),
      )
      ..registerFactory(() => BackupCubit(_EmptyLedger(), _NoFiles(), settings))
      ..registerFactory(
        () => HelpCubit(
          _NoWayOut(),
          Future.value(
            const AppAbout(
              version: '0.1.0',
              build: '1',
              system: 'Android 14',
              locale: 'en-US',
            ),
          ),
        ),
      )
      ..registerSingleton<SettingsStore>(settings)
      ..registerSingleton<HelpLinks>(links)
      ..registerSingleton<StatementFiles>(statements)
      ..registerFactory(
        () => SettingsCubit(
          settings,
          deviceLanguage: 'en',
          baseCurrency: BaseCurrency(null),
          monthStart: MonthStart(1),
        ),
      )
      ..registerFactory(() => OperationsCubit(transactions))
      ..registerFactoryParam<AccountCubit, String, void>(
        (id, _) => AccountCubit(transactions, id),
      )
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

    testWidgets('a language picked on the way keeps what was typed', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BirkaApp(getIt: getIt, onboarding: true));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Get started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Card');
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Русский'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Начать'));
      await tester.pumpAndSettle();

      expect(find.text('Первый счёт'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Card'), findsOneWidget);
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
    final card = AccountBalance(coffee.account!, Money(100, Currency.rub));
    overview.accounts = [card];
    transactions.account = card;
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CARD'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountPage), findsOneWidget);
    expect(pageOf(tester), isA<BirkaZoomPage<void>>());

    await tester.tap(find.bySemanticsLabel(t.transactions.back));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.overview.allAccounts(n: 1).toUpperCase()));
    await tester.pumpAndSettle();
    expect(find.byType(AccountsPage), findsOneWidget);
  });

  testWidgets('all accounts open one from its card and from its row', (
    tester,
  ) async {
    final coffee = _coffee();
    final card = AccountBalance(coffee.account!, Money(100, Currency.rub));
    overview.accounts = [card];
    accounts.balances = [card];
    transactions.account = card;
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.overview.allAccounts(n: 1).toUpperCase()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CARD'));
    await tester.pumpAndSettle();
    expect(pageOf(tester), isA<BirkaZoomPage<void>>());

    await tester.tap(find.bySemanticsLabel(t.transactions.back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Card'));
    await tester.pumpAndSettle();
    expect(pageOf(tester), isA<MaterialPage<void>>());
  });

  group('the page of an account', () {
    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(402, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final coffee = _coffee();
      final card = AccountBalance(coffee.account!, Money(100, Currency.rub));
      overview.accounts = [card];
      transactions
        ..account = card
        ..operations = [coffee];
      await tester.pumpWidget(BirkaApp(getIt: getIt));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CARD'));
      await tester.pumpAndSettle();
    }

    testWidgets('leads to the form and back', (tester) async {
      await open(tester);

      await tester.tap(find.bySemanticsLabel(t.transactions.edit));
      await tester.pumpAndSettle();
      expect(find.byType(AccountFormPage), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(t.app.close));
      await tester.pumpAndSettle();

      expect(find.byType(AccountFormPage), findsNothing);
      expect(find.byType(AccountPage), findsOneWidget);
      expect(pageOf(tester), isA<BirkaZoomPage<void>>());
    });

    testWidgets('leads to an operation and back', (tester) async {
      await open(tester);

      await tester.tap(find.byType(OperationRow));
      await tester.pumpAndSettle();
      expect(find.byType(OperationPage), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(t.transactions.back));
      await tester.pumpAndSettle();

      expect(find.byType(OperationPage), findsNothing);
      expect(find.byType(AccountPage), findsOneWidget);
    });
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

  testWidgets('More leads to the inbox, which says all is sorted', (
    tester,
  ) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.more));
    await tester.pumpAndSettle();
    expect(find.text(t.inbox.title), findsOneWidget);
    expect(find.text(t.inbox.emptyTitle), findsOneWidget);
    await tester.tap(find.text(t.inbox.title));
    await tester.pumpAndSettle();

    expect(find.byType(InboxPage), findsOneWidget);
  });

  testWidgets('the bell of the overview opens the notices and leads back', (
    tester,
  ) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(t.notifications.bell));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);
    expect(find.text(t.notifications.emptyTitle), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(t.notifications.back));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsPage), findsNothing);
  });

  testWidgets('the overview shows no way to an empty inbox', (tester) async {
    final coffee = _coffee();
    overview.accounts = [
      AccountBalance(coffee.account!, Money(100, Currency.rub)),
    ];
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    expect(find.byType(InboxCard), findsOneWidget);
    expect(find.textContaining('inbox'), findsNothing);
  });

  testWidgets('the setting waits for the next launch', (tester) async {
    transactions.operations = [_coffee()];
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.more));
    await tester.pumpAndSettle();
    final hide = find.descendant(
      of: find.ancestor(
        of: find.text(t.settings.hideAmounts),
        matching: find.byType(GlassListRow),
      ),
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(hide);
    await tester.pumpAndSettle();
    await tester.tap(hide);
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

  testWidgets('the data open from the more tab, over the bar', (tester) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.app.data));
    await tester.pumpAndSettle();

    expect(find.byType(BackupPage), findsOneWidget);
    expect(find.byType(GlassNavBar), findsNothing);
    expect(find.text(t.backup.noCopyYet), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(t.backup.back));
    await tester.pumpAndSettle();
    expect(find.byType(GlassNavBar), findsOneWidget);
  });

  testWidgets('help opens from the more tab, over the bar', (tester) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.more));
    await tester.pumpAndSettle();
    final page = find.descendant(
      of: find.byType(MorePage),
      matching: find.byType(Scrollable),
    );
    final credit = find.textContaining('cbr-xml-daily.ru');
    await tester.scrollUntilVisible(credit, 200, scrollable: page.first);
    // To the end, where nothing hides under the bar.
    await tester.drag(page.first, const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(credit, findsOneWidget);
    await tester.tap(find.text(t.app.help));
    await tester.pumpAndSettle();

    expect(find.byType(HelpPage), findsOneWidget);
    expect(find.byType(GlassNavBar), findsNothing);
    expect(find.text(t.help.storageQuestion), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(t.help.back));
    await tester.pumpAndSettle();
    expect(find.byType(GlassNavBar), findsOneWidget);
  });

  group('a tapped reminder', () {
    testWidgets('of the day opens the regular payments', (tester) async {
      await tester.pumpWidget(BirkaApp(getIt: getIt));
      await tester.pumpAndSettle();

      reminders.taps.add(const ReminderTap('rent'));
      await tester.pumpAndSettle();
      expect(find.byType(SchedulesPage), findsOneWidget);
      expect(forms, isEmpty);
    });

    testWidgets('of the day before opens the payment', (tester) async {
      await tester.pumpWidget(BirkaApp(getIt: getIt));
      await tester.pumpAndSettle();

      reminders.taps.add(const ReminderTap('rent', early: true));
      await tester.pumpAndSettle();
      // The form of that payment opened, not the list. Here the payment is
      // gone, as one deleted since the reminder came, so the form closed at
      // once.
      expect(forms, ['rent']);
      expect(find.byType(SchedulesPage), findsNothing);
      expect(find.byType(ScheduleFormPage), findsNothing);
      expect(find.byType(GlassNavBar), findsOneWidget);
    });
  });

  testWidgets('the more tab opens the window of a statement', (tester) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.app.more));
    await tester.pumpAndSettle();

    expect(find.text(t.app.soon.toUpperCase()), findsNothing);
    await tester.tap(find.text(t.app.import));
    await tester.pumpAndSettle();

    expect(statements.opened, 1);
    expect(find.byType(MorePage), findsOneWidget);
  });

  Future<Finder> scrollToTheEndOfMore(WidgetTester tester) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.app.more));
    await tester.pumpAndSettle();
    final code = find.text(t.app.sourceCode);
    final page = find
        .descendant(
          of: find.byType(MorePage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(code, 200, scrollable: page);
    // To the end, where nothing hides under the bar.
    await tester.drag(page, const Offset(0, -1000));
    await tester.pumpAndSettle();
    return code;
  }

  testWidgets('the more tab ends with the version, the code and the rates', (
    tester,
  ) async {
    final code = await scrollToTheEndOfMore(tester);

    expect(
      find.text('Birka $appVersion · ${t.app.keptOnDevice}'),
      findsOneWidget,
    );
    expect(find.textContaining('cbr-xml-daily.ru'), findsOneWidget);
    await tester.tap(code);
    await tester.pumpAndSettle();
    expect(links.pages, [codePage]);
    expect(find.text(t.help.noPage), findsNothing);
  });

  testWidgets('says so when the code does not open', (tester) async {
    links.opens = false;
    final code = await scrollToTheEndOfMore(tester);

    await tester.tap(code);
    await tester.pumpAndSettle();
    expect(find.text(t.help.noPage), findsOneWidget);
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
