import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:inbox_flutter/inbox_flutter.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:rates/rates.dart';

import 'fakes.dart';

/// The made-up ledger of [_base], whose transactions can change.
final class _Live implements InboxRepository {
  _Live(this._base) {
    transactions.add(_base.transactions);
  }

  final FakeInboxRepository _base;

  /// The transactions as they come, those of [_base] first.
  final transactions = StreamController<List<Transaction>>();

  @override
  Stream<List<Transaction>> watchTransactions() => transactions.stream;

  @override
  Stream<List<Account>> watchAccounts() => _base.watchAccounts();

  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) =>
      _base.watchCategories(kind);

  @override
  Stream<RateBook> watchRates() => _base.watchRates();

  @override
  Stream<List<LedgerImport>> watchImports() => _base.watchImports();

  @override
  Future<void> categorize(List<(Transaction, String)> choices) =>
      _base.categorize(choices);

  @override
  Future<String> makeTransfer(TransferPair pair) => _base.makeTransfer(pair);
}

void main() {
  var opened = 0;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.ru);
    opened = 0;
  });
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Future<void> pump(
    WidgetTester tester,
    InboxRepository repository,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(780, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final cubit = InboxSummaryCubit(
      repository,
      DismissedPairs(FakeSettingsStore()),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: ListView(children: [child]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the strip on the overview', () {
    testWidgets('says how much waits, of what and after which import', (
      tester,
    ) async {
      await pump(tester, october(), InboxCard(onOpen: () => opened++));

      expect(find.text('3 ждут решения во «Входящих»'), findsOneWidget);
      expect(
        find.text(
          '2 без категории и перевод со счёта «Wise USD» · после импорта '
          'Альфа-Банка',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('3 ждут решения во «Входящих»'));
      expect(opened, 1);
    });

    testWidgets('stays away when nothing waits', (tester) async {
      await pump(
        tester,
        FakeInboxRepository(),
        InboxCard(onOpen: () => opened++),
      );

      expect(find.textContaining('ждут решения'), findsNothing);
    });

    testWidgets('closes once everything is sorted', (tester) async {
      final ledger = _Live(october());
      await pump(tester, ledger, InboxCard(onOpen: () => opened++));
      expect(find.text('3 ждут решения во «Входящих»'), findsOneWidget);

      ledger.transactions.add(const []);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('3 ждут решения во «Входящих»'), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.textContaining('ждут решения'), findsNothing);
    });
  });

  group('the row in More', () {
    testWidgets('says how much waits after which import, with its count', (
      tester,
    ) async {
      await pump(tester, october(), InboxTile(onOpen: () => opened++));

      expect(find.text('Входящие'), findsOneWidget);
      expect(
        find.text('3 ждут решения · после импорта Альфа-Банка'),
        findsOneWidget,
      );
      expect(find.text('3'), findsOneWidget);
      await tester.tap(find.text('Входящие'));
      expect(opened, 1);
    });

    testWidgets('says that all is sorted', (tester) async {
      await pump(
        tester,
        FakeInboxRepository(),
        InboxTile(onOpen: () => opened++),
      );

      expect(find.text('Всё разобрано'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });
  });
}
