import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:notifications_common/notifications_common.dart';
import 'package:notifications_flutter/notifications_flutter.dart';

/// Wednesday, November 25, 2026, 10:00, as on the boards.
final boardNow = DateTime(2026, 11, 25, 10);

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

/// [text] with the spaces of formatted amounts.
String nb(String text) => text.replaceAll(' ', String.fromCharCode(0xA0));

/// The notices of the boards: the rent that waits today and the statement of
/// last night, new, and below them what became of earlier times.
List<Notice> boardNotices() => [
  PaymentNotice(
    id: 'rent',
    at: DateTime(2026, 11, 25, 9),
    scheduleId: 'rent',
    time: CivilDate(2026, 11, 25),
    name: 'Аренда',
    kind: TransactionKind.expense,
    amount: rub(45000),
  ),
  ImportNotice(
    id: 'alfa',
    at: DateTime(2026, 11, 24, 21, 40),
    importId: 'alfa',
    fileName: 'alfa-2026-11.xlsx',
    format: 'alfa',
    firstDay: CivilDate(2026, 11, 1),
    lastDay: CivilDate(2026, 11, 23),
    transactions: 34,
    waiting: 3,
  ),
  PaymentNotice(
    id: 'salary',
    at: DateTime(2026, 11, 5, 9),
    readAt: DateTime(2026, 11, 5, 9, 14),
    scheduleId: 'salary',
    time: CivilDate(2026, 11, 5),
    name: 'Зарплата',
    kind: TransactionKind.income,
    amount: rub(120000),
    outcome: NoticeOutcome.posted,
    outcomeAt: DateTime(2026, 11, 5, 9, 14),
    next: CivilDate(2026, 12, 5),
  ),
  PaymentNotice(
    id: 'gym',
    at: DateTime(2026, 11, 3, 9),
    readAt: DateTime(2026, 11, 3, 12),
    scheduleId: 'gym',
    time: CivilDate(2026, 11, 3),
    name: 'Спортзал',
    kind: TransactionKind.expense,
    amount: rub(3500),
    outcome: NoticeOutcome.skipped,
    outcomeAt: DateTime(2026, 11, 3, 12, 30),
    next: CivilDate(2026, 12, 3),
  ),
];

/// Notices kept in memory, which mark themselves read as asked.
final class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository(this._notices);

  List<Notice> _notices;
  final _changes = StreamController<List<Notice>>.broadcast();

  /// The ids that were read, in order.
  final read_ = <String>[];

  /// The clock of the repository.
  DateTime clock = boardNow;

  @override
  DateTime now() => clock;

  @override
  Stream<List<Notice>> watchNotices() => Stream.multi((controller) {
    controller.add(_notices);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Stream<int> watchNew() =>
      watchNotices().map((it) => it.where((n) => n.isNew).length);

  @override
  Future<void> read([Iterable<String>? ids]) async {
    final marked = ids?.toSet();
    _notices = [
      for (final notice in _notices)
        if (notice.isNew && (marked == null || marked.contains(notice.id)))
          _readOf(notice)
        else
          notice,
    ];
    read_.addAll([...?marked]);
    _changes.add(_notices);
  }

  Notice _readOf(Notice notice) => switch (notice) {
    PaymentNotice() => PaymentNotice(
      id: notice.id,
      at: notice.at,
      readAt: clock,
      scheduleId: notice.scheduleId,
      time: notice.time,
      name: notice.name,
      kind: notice.kind,
      amount: notice.amount,
      advance: notice.advance,
      postsItself: notice.postsItself,
      outcome: notice.outcome,
      outcomeAt: notice.outcomeAt,
      next: notice.next,
    ),
    ImportNotice() => ImportNotice(
      id: notice.id,
      at: notice.at,
      readAt: clock,
      importId: notice.importId,
      fileName: notice.fileName,
      format: notice.format,
      firstDay: notice.firstDay,
      lastDay: notice.lastDay,
      transactions: notice.transactions,
      waiting: notice.waiting,
      undone: notice.undone,
    ),
  };

  @override
  Future<void> forgetOld() async {}
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Future<List<(NoticePlace, String?)>> pump(
    WidgetTester tester,
    FakeNotificationsRepository repository,
  ) async {
    tester.view.physicalSize = const Size(780, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final cubit = NotificationsCubit(repository);
    addTearDown(cubit.close);
    final opened = <(NoticePlace, String?)>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: BlocProvider.value(
          value: cubit,
          child: NotificationsPage(
            onBack: () {},
            onOpen: (place, id) => opened.add((place, id)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return opened;
  }

  Color? colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  testWidgets('shows the new on top and the history by days', (tester) async {
    await pump(tester, FakeNotificationsRepository(boardNotices()));

    expect(find.text('НОВЫЕ · 2'), findsOneWidget);
    expect(find.text('Прочитать все'), findsOneWidget);
    expect(find.text('Аренда · ${nb('45 000 ₽')}'), findsOneWidget);
    expect(find.text('Сегодня, ждёт подтверждения'), findsOneWidget);
    expect(find.text('Альфа-Банк · ноябрь'), findsOneWidget);
    expect(find.text('3 из 34 ждут во «Входящих»'), findsOneWidget);
    expect(find.text('вчера'), findsOneWidget);
    expect(find.text('5 НОЯБРЯ'), findsOneWidget);
    expect(find.text('3 НОЯБРЯ'), findsOneWidget);
    expect(find.text('Провели в 9:14'), findsOneWidget);
    expect(find.text('Пропустили · следующий 3 декабря'), findsOneWidget);
    expect(find.text('Birka хранит уведомления 90 дней'), findsOneWidget);
    const colors = BirkaColors.dark;
    expect(colorOf(tester, 'Провели в 9:14'), colors.positive);
    expect(
      colorOf(tester, 'Пропустили · следующий 3 декабря'),
      colors.textSubtle,
    );
  });

  testWidgets('reads all and takes the new into the history', (tester) async {
    final repository = FakeNotificationsRepository(boardNotices());
    await pump(tester, repository);

    await tester.tap(find.text('Прочитать все'));
    await tester.pumpAndSettle();

    expect(find.text('НОВЫЕ · 2'), findsNothing);
    expect(find.text('СЕГОДНЯ'), findsOneWidget);
    expect(find.text('ВЧЕРА'), findsOneWidget);
    expect(find.text('Ждёт подтверждения'), findsOneWidget);
    expect(
      colorOf(tester, 'Ждёт подтверждения'),
      const Color(BirkaTokens.colorPaletteAmber),
    );
  });

  testWidgets('opens where a notice leads and marks it read', (tester) async {
    final repository = FakeNotificationsRepository(boardNotices());
    final opened = await pump(tester, repository);

    await tester.tap(find.text('Аренда · ${nb('45 000 ₽')}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Альфа-Банк · ноябрь'));
    await tester.pumpAndSettle();

    expect(opened, [(NoticePlace.schedules, null), (NoticePlace.inbox, null)]);
    expect(repository.read_, ['rent', 'alfa']);
    expect(find.text('НОВЫЕ · 2'), findsNothing);
  });

  testWidgets('narrows the feed to one source', (tester) async {
    await pump(tester, FakeNotificationsRepository(boardNotices()));

    await tester.tap(find.text('Импорт'));
    await tester.pumpAndSettle();

    expect(find.text('Альфа-Банк · ноябрь'), findsOneWidget);
    expect(find.text('Аренда · ${nb('45 000 ₽')}'), findsNothing);
    expect(find.text('5 НОЯБРЯ'), findsNothing);
  });

  testWidgets('says that it is quiet while nothing came', (tester) async {
    await pump(tester, FakeNotificationsRepository(const []));

    expect(find.text('Пока тихо'), findsOneWidget);
    expect(find.text('Прочитать все'), findsNothing);
  });

  testWidgets('the bell counts the new and opens the feed', (tester) async {
    final repository = FakeNotificationsRepository(boardNotices());
    final summary = NotificationsSummaryCubit(repository);
    addTearDown(summary.close);
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: BirkaTheme.dark(),
        home: Scaffold(
          body: Center(
            child: BlocProvider.value(
              value: summary,
              child: NotificationsBell(onOpen: () => opened++),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.bySemanticsLabel('Уведомления, 2 новых'), findsOneWidget);
    await tester.tap(find.byType(NotificationsBell));
    expect(opened, 1);

    await repository.read();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Уведомления'), findsOneWidget);
  });
}
