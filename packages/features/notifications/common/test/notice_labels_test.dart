import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:notifications_common/notifications_common.dart';
import 'package:test/test.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

/// [text] with the spaces of formatted amounts.
String nb(String text) => text.replaceAll(' ', String.fromCharCode(0xA0));

/// Wednesday, November 25, 2026, as on the boards.
final today = CivilDate(2026, 11, 25);

PaymentNotice payment({
  String name = 'Аренда',
  int rubles = 45000,
  CivilDate? time,
  DateTime? at,
  DateTime? readAt,
  TransactionKind kind = TransactionKind.expense,
  bool advance = false,
  bool postsItself = false,
  NoticeOutcome? outcome,
  DateTime? outcomeAt,
  CivilDate? next,
}) => PaymentNotice(
  id: '$name ${time ?? today}',
  at: at ?? DateTime(2026, 11, 25, 9),
  readAt: readAt,
  scheduleId: name,
  time: time ?? today,
  name: name,
  kind: kind,
  amount: rub(rubles),
  advance: advance,
  postsItself: postsItself,
  outcome: outcome,
  outcomeAt: outcomeAt,
  next: next,
);

ImportNotice import({
  int transactions = 34,
  int waiting = 3,
  bool undone = false,
  String? format = 'alfa',
  CivilDate? firstDay,
}) => ImportNotice(
  id: 'import',
  at: DateTime(2026, 11, 24, 21, 40),
  importId: 'alfa',
  fileName: 'alfa-2026-11.xlsx',
  format: format,
  firstDay: firstDay ?? CivilDate(2026, 11, 1),
  lastDay: CivilDate(2026, 11, 23),
  transactions: transactions,
  waiting: waiting,
  undone: undone,
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('a notice says', () {
    test('what it is about', () {
      expect(
        noticeTitle(payment(), thisYear: 2026),
        'Аренда · ${nb('45 000 ₽')}',
      );
      expect(
        noticeTitle(
          payment(
            name: 'Зарплата',
            rubles: 60000,
            kind: TransactionKind.income,
            advance: true,
          ),
          thisYear: 2026,
        ),
        'Аванс · ${nb('+60 000 ₽')}',
      );
      expect(noticeTitle(import(), thisYear: 2026), 'Альфа-Банк · ноябрь');
      expect(
        noticeTitle(
          import(format: null, firstDay: CivilDate(2025, 12, 20)),
          thisYear: 2026,
        ),
        'alfa-2026-11.xlsx · декабрь 2025 – ноябрь',
      );
    });

    test('when its time comes, while it is new', () {
      String fresh(PaymentNotice notice) =>
          noticeLine(notice, today: today, fresh: true).$1;

      expect(fresh(payment()), 'Сегодня, ждёт подтверждения');
      expect(
        fresh(payment(time: CivilDate(2026, 11, 23))),
        'Ждёт подтверждения',
      );
      expect(
        fresh(payment(time: CivilDate(2026, 11, 26))),
        'Завтра, 26 ноября',
      );
      expect(fresh(payment(postsItself: true)), 'Сегодня, проведётся сам');
    });

    test('what became of it, in the history', () {
      (String, NoticeTone) line(PaymentNotice notice) =>
          noticeLine(notice, today: today);

      expect(line(payment()), ('Ждёт подтверждения', NoticeTone.waits));
      expect(
        line(
          payment(
            outcome: NoticeOutcome.posted,
            outcomeAt: DateTime(2026, 11, 25, 9, 14),
          ),
        ),
        ('Провели в 9:14', NoticeTone.done),
      );
      expect(
        line(
          payment(
            outcome: NoticeOutcome.posted,
            outcomeAt: DateTime(2026, 11, 27, 9, 14),
          ),
        ),
        ('Провели 27 ноября', NoticeTone.done),
      );
      expect(
        line(payment(outcome: NoticeOutcome.postedItself)),
        ('Провёлся сам', NoticeTone.done),
      );
      expect(
        line(
          payment(
            outcome: NoticeOutcome.skipped,
            next: CivilDate(2026, 12, 25),
          ),
        ),
        ('Пропустили · следующий 25 декабря', NoticeTone.left),
      );
      expect(
        line(payment(outcome: NoticeOutcome.found)),
        ('Нашли в выписке', NoticeTone.done),
      );
    });

    test('what of an import waits for a category', () {
      (String, NoticeTone) line(ImportNotice notice) =>
          noticeLine(notice, today: today);

      expect(
        line(import()),
        ('3 из 34 ждут во «Входящих»', NoticeTone.waits),
      );
      expect(
        line(import(waiting: 1)),
        ('1 из 34 ждёт во «Входящих»', NoticeTone.waits),
      );
      expect(
        line(import(waiting: 0)),
        ('Добавили 34 операции', NoticeTone.plain),
      );
      expect(
        line(import(undone: true)),
        ('Импорт отменён', NoticeTone.left),
      );
    });

    test('when it came and where a tap leads', () {
      expect(noticeMoment(payment(), today: today), '9:00');
      expect(noticeMoment(import(), today: today), 'вчера');
      expect(
        noticeDayHeading(CivilDate(2026, 11, 5), today: today),
        '5 ноября',
      );
      expect(
        noticePlace(payment(), today: today),
        (place: NoticePlace.schedules, id: null),
      );
      expect(
        noticePlace(payment(time: CivilDate(2026, 11, 26)), today: today),
        (place: NoticePlace.schedule, id: 'Аренда'),
      );
      expect(
        noticePlace(import(), today: today),
        (place: NoticePlace.inbox, id: null),
      );
      expect(noticePlace(import(waiting: 0), today: today), isNull);
    });
  });
}
