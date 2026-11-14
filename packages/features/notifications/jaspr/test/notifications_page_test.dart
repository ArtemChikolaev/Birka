import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:notifications_common/notifications_common.dart';
import 'package:notifications_jaspr/notifications_jaspr.dart';

/// Wednesday, November 25, 2026, 10:00, as on the boards.
final _now = DateTime(2026, 11, 25, 10);

Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

/// [text] with the spaces of formatted amounts.
String _nb(String text) => text.replaceAll(' ', String.fromCharCode(0xA0));

/// The notices of the boards: the rent that waits today and the statement of
/// last night, new, and below them what became of earlier ones.
List<Notice> _boardNotices() => [
  PaymentNotice(
    id: 'rent',
    at: DateTime(2026, 11, 25, 9),
    scheduleId: 'rent',
    time: CivilDate(2026, 11, 25),
    name: 'Аренда',
    kind: TransactionKind.expense,
    amount: _rub(45000),
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
    amount: _rub(120000),
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
    amount: _rub(3500),
    outcome: NoticeOutcome.skipped,
    outcomeAt: DateTime(2026, 11, 3, 12, 30),
    next: CivilDate(2026, 12, 3),
  ),
  ImportNotice(
    id: 'tbank',
    at: DateTime(2026, 10, 28, 20, 12),
    readAt: DateTime(2026, 10, 28, 21),
    importId: 'tbank',
    fileName: 'tbank-2026-10.csv',
    format: 'tbank',
    firstDay: CivilDate(2026, 10, 1),
    lastDay: CivilDate(2026, 10, 27),
    transactions: 20,
    waiting: 2,
  ),
];

/// Notices kept in memory, which mark themselves read as asked.
final class _Notices implements NotificationsRepository {
  _Notices(this._notices, {this.broken = false});

  List<Notice> _notices;
  final bool broken;
  final _changes = StreamController<List<Notice>>.broadcast();

  /// The ids that were read one by one, in order.
  final read_ = <String>[];

  @override
  DateTime now() => _now;

  @override
  Stream<List<Notice>> watchNotices() => Stream.multi((controller) {
    if (broken) {
      controller.addError(StateError('disk'));
      return;
    }
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
      readAt: _now,
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
    DebtNotice() => DebtNotice(
      id: notice.id,
      at: notice.at,
      readAt: _now,
      debtId: notice.debtId,
      name: notice.name,
      side: notice.side,
      due: notice.due,
      owed: notice.owed,
      left: notice.left,
      since: notice.since,
      note: notice.note,
      settledOn: notice.settledOn,
      gone: notice.gone,
    ),
    ImportNotice() => ImportNotice(
      id: notice.id,
      at: notice.at,
      readAt: _now,
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

/// The DOM element with exactly these [classes].
Finder _withClasses(String classes) => find.byComponentPredicate(
  (component) => component is DomComponent && component.classes == classes,
  description: 'element with classes "$classes"',
);

/// The addresses of the links on the page.
List<String?> _links() => [
  for (final element in find.tag('a').evaluate())
    (element.component as DomComponent).attributes?['href'],
];

/// The color of the line that says [text].
String? _colorOf(String text) {
  final line = find.ancestor(of: find.text(text), matching: find.tag('span'));
  return (line.evaluate().first.component as DomComponent)
      .styles
      ?.properties['color'];
}

/// The button around [text].
Finder _buttonOf(String text) =>
    find.ancestor(of: find.text(text), matching: find.tag('button')).first;

void main() {
  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  /// The page on [notices] as the site has it, where only the inbox is a
  /// place to go, and the places it went to.
  List<String> pump(
    ComponentTester tester,
    NotificationsRepository notices, {
    bool wide = false,
  }) {
    final opened = <String>[];
    tester.pumpComponent(
      BlocProvider(
        create: (_) => NotificationsCubit(notices),
        child: NotificationsPage(
          backHref: 'overview/',
          hrefOf: (place, _) => place == NoticePlace.inbox ? 'inbox/' : null,
          onOpen: opened.add,
          wide: wide,
        ),
      ),
    );
    return opened;
  }

  testComponents('a wide page tells at the side what comes here', (
    tester,
  ) async {
    pump(tester, _Notices(_boardNotices()), wide: true);
    await tester.pump();

    final side = find.byComponentPredicate(
      (component) =>
          component is DomComponent &&
          component.classes == 'birka-split__aside',
    );
    expect(
      find.descendant(of: side, matching: find.text('Что сюда приходит')),
      findsOneComponent,
    );
    expect(
      find.descendant(of: side, matching: find.text('Новые · 2')),
      findsNothing,
    );
    expect(find.text('Новые · 2'), findsOneComponent);
  });

  testComponents('shows the new on top and the history by days', (
    tester,
  ) async {
    pump(tester, _Notices(_boardNotices()));
    await tester.pump();

    expect(find.text('Уведомления'), findsOneComponent);
    expect(find.text('2 новых · история за 90 дней'), findsOneComponent);
    expect(find.text('Прочитать все'), findsOneComponent);
    expect(find.text('Новые · 2'), findsOneComponent);
    expect(find.text('Аренда · ${_nb('45 000 ₽')}'), findsOneComponent);
    expect(find.text('Сегодня, ждёт подтверждения'), findsOneComponent);
    expect(find.text('Альфа-Банк · ноябрь'), findsOneComponent);
    expect(find.text('3 из 34 ждут во «Входящих»'), findsOneComponent);
    expect(find.text('9:00'), findsNComponents(3));
    expect(find.text('вчера'), findsOneComponent);
    expect(find.text('5 ноября'), findsOneComponent);
    expect(find.text('3 ноября'), findsOneComponent);
    expect(find.text('28 октября'), findsOneComponent);
    expect(find.text('Birka хранит уведомления 90 дней'), findsOneComponent);
    expect(_colorOf('Провели в 9:14'), 'var(--color-positive)');
    expect(
      _colorOf('Пропустили · следующий 3 декабря'),
      'var(--color-text-subtle)',
    );
    expect(
      _colorOf('2 из 20 ждут во «Входящих»'),
      'var(--color-palette-amber)',
    );
    // The new ones are buttons that read them first; of the history, only
    // what the site has a page for is a link.
    expect(_links(), ['overview/', 'inbox/']);
    expect(_withClasses('notifications__dot'), findsNComponents(2));
  });

  testComponents('reads all and closes the new into the history', (
    tester,
  ) async {
    fakeAsync((time) {
      pump(tester, _Notices(_boardNotices()));
      time.flushMicrotasks();

      unawaited(tester.click(_buttonOf('Прочитать все'), pump: false));
      time.flushMicrotasks();

      // The dots go out and the group folds, while the days it goes to open.
      expect(
        _withClasses('notifications__fold notifications__fold--closing'),
        findsOneComponent,
      );
      expect(
        _withClasses('notifications__fold notifications__fold--opening'),
        findsNComponents(2),
      );
      expect(find.text('Сегодня'), findsOneComponent);
      expect(find.text('Вчера'), findsOneComponent);
      expect(
        find.text('Всё прочитано · история за 90 дней'),
        findsOneComponent,
      );

      time.elapse(NotificationsPage.closing);

      expect(find.text('Новые · 2'), findsNothing);
      expect(find.text('Прочитать все'), findsNothing);
      expect(_withClasses('notifications__fold'), findsNComponents(5));
      expect(find.text('Ждёт подтверждения'), findsOneComponent);
      expect(_colorOf('Ждёт подтверждения'), 'var(--color-palette-amber)');
    });
  });

  testComponents('a new one leads where it is dealt with once read', (
    tester,
  ) async {
    final notices = _Notices(_boardNotices());
    final opened = pump(tester, notices);
    await tester.pump();

    await tester.click(_buttonOf('Альфа-Банк · ноябрь'));
    await tester.pump();

    expect(notices.read_, ['alfa']);
    expect(opened, ['inbox/']);
  });

  testComponents('one the site has no page for goes into the history', (
    tester,
  ) async {
    final notices = _Notices(_boardNotices());
    final opened = pump(tester, notices);
    await tester.pump();

    await tester.click(_buttonOf('Аренда · ${_nb('45 000 ₽')}'));
    await tester.pump();

    expect(notices.read_, ['rent']);
    expect(opened, isEmpty);
    expect(find.text('Новые · 1'), findsOneComponent);
    expect(find.text('Сегодня'), findsOneComponent);
    expect(find.text('Ждёт подтверждения'), findsOneComponent);
  });

  testComponents('one that goes into a day that was there opens in it', (
    tester,
  ) async {
    fakeAsync((time) {
      final notices = _Notices([
        ..._boardNotices(),
        ImportNotice(
          id: 'sber',
          at: DateTime(2026, 11, 25, 8, 30),
          readAt: DateTime(2026, 11, 25, 8, 40),
          importId: 'sber',
          fileName: 'sber-2026-11.pdf',
          format: 'sber',
          firstDay: CivilDate(2026, 11, 1),
          lastDay: CivilDate(2026, 11, 24),
          transactions: 12,
          waiting: 0,
        ),
      ]);
      pump(tester, notices);
      time.flushMicrotasks();
      expect(find.text('Сегодня'), findsOneComponent);

      unawaited(
        tester.click(_buttonOf('Аренда · ${_nb('45 000 ₽')}'), pump: false),
      );
      time.flushMicrotasks();

      // The day stays as it was and takes the rent in.
      expect(
        _withClasses('notifications__fold notifications__fold--opening'),
        findsNothing,
      );
      expect(
        _withClasses('glass-row glass-row--action glass-row--entering'),
        findsNothing,
      );
      expect(_withClasses('glass-row glass-row--entering'), findsOneComponent);
      expect(find.text('Ждёт подтверждения'), findsOneComponent);

      time.elapse(NotificationsPage.closing);

      expect(_withClasses('glass-row glass-row--entering'), findsNothing);
      expect(find.text('Новые · 1'), findsOneComponent);
    });
  });

  testComponents('narrows the feed to one source', (tester) async {
    pump(tester, _Notices(_boardNotices()));
    await tester.pump();

    expect(find.text('Все'), findsOneComponent);
    expect(find.text('Платежи'), findsOneComponent);
    await tester.click(_buttonOf('Импорт'));
    await tester.pump();

    expect(find.text('Альфа-Банк · ноябрь'), findsOneComponent);
    expect(find.text('Т-Банк · октябрь'), findsOneComponent);
    expect(find.text('Аренда · ${_nb('45 000 ₽')}'), findsNothing);
    expect(find.text('5 ноября'), findsNothing);
  });

  testComponents('the imports alone need no chips', (tester) async {
    pump(
      tester,
      _Notices([
        for (final notice in _boardNotices())
          if (notice is ImportNotice) notice,
      ]),
    );
    await tester.pump();

    expect(find.text('Новые · 1'), findsOneComponent);
    expect(find.text('Все'), findsNothing);
  });

  testComponents('says that it is quiet while nothing came', (tester) async {
    pump(tester, _Notices(const []));
    await tester.pump();

    expect(find.text('Пока тихо'), findsOneComponent);
    expect(
      find.text('Здесь появятся итоги импорта выписок.'),
      findsOneComponent,
    );
    expect(find.text('Прочитать все'), findsNothing);
    expect(find.text('Всё прочитано · история за 90 дней'), findsNothing);
  });

  testComponents('says so when the notices cannot be read', (tester) async {
    pump(tester, _Notices(const [], broken: true));
    await tester.pump();

    expect(find.text('Не удалось прочитать уведомления.'), findsOneComponent);
  });

  testComponents('the bell counts the new and leads to the feed', (
    tester,
  ) async {
    final notices = _Notices(_boardNotices());
    final summary = NotificationsSummaryCubit(notices);
    addTearDown(summary.close);
    tester.pumpComponent(
      BlocProvider.value(
        value: summary,
        child: const NotificationsBell(href: 'notifications/'),
      ),
    );
    await tester.pump();

    final bell = find.tag('a');
    expect(_links(), ['notifications/']);
    expect(
      (bell.evaluate().single.component as DomComponent)
          .attributes?['aria-label'],
      'Уведомления, 2 новых',
    );
    expect(find.text('2'), findsOneComponent);

    await notices.read();
    await tester.pump();

    expect(
      (bell.evaluate().single.component as DomComponent)
          .attributes?['aria-label'],
      'Уведомления',
    );
    expect(
      _withClasses(
        'text-label glass-icon-button__badge glass-icon-button__badge--off',
      ),
      findsOneComponent,
    );
  });

  testComponents('the day of a debt reads as on the phone and leads to the '
      'debt', (tester) async {
    final notices = _Notices([
      DebtNotice(
        id: 'dima',
        at: DateTime(2026, 11, 25, 9),
        debtId: 'dima',
        name: 'Дима',
        side: DebtSide.lent,
        due: CivilDate(2026, 11, 25),
        owed: Money(12000, Currency.usd),
        left: Money(12000, Currency.usd),
        since: CivilDate(2026, 10, 20),
        note: 'За квартиру в Тбилиси',
      ),
      ..._boardNotices(),
    ]);
    final opened = <String>[];
    tester.pumpComponent(
      BlocProvider(
        create: (_) => NotificationsCubit(notices),
        child: NotificationsPage(
          backHref: 'overview/',
          hrefOf: (place, id) => switch (place) {
            NoticePlace.debt => 'debts/#$id',
            NoticePlace.inbox => 'inbox/',
            _ => null,
          },
          onOpen: opened.add,
        ),
      ),
    );
    await tester.pump();

    final title = 'Срок сегодня · Дима, ${_nb(r'120 $')}';
    expect(find.text(title), findsOneComponent);
    expect(
      find.text('За квартиру в Тбилиси · с 20 октября'),
      findsOneComponent,
    );
    expect(find.text('Долги'), findsOneComponent);

    await tester.click(_buttonOf(title));
    await tester.pump();
    expect(notices.read_, ['dima']);
    expect(opened, ['debts/#dima']);
  });
}
