import 'package:backup_common/backup_common.dart';
import 'package:l10n/l10n.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  final now = DateTime(2026, 11, 2, 22);

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('a copy says when it was made in the words of people', () {
    expect(
      copyMomentLabel(DateTime(2026, 11, 2, 21, 40), now: now),
      'сегодня, 21:40',
    );
    expect(
      copyMomentLabel(DateTime(2026, 11, 1, 9, 5), now: now),
      'вчера, 09:05',
    );
    expect(
      copyMomentLabel(DateTime(2026, 10, 28, 21, 40), now: now),
      '28\u00A0октября, 21:40',
    );
    expect(
      copyMomentLabel(DateTime(2025, 12, 31, 23, 59).toUtc(), now: now),
      '31\u00A0декабря\u00A02025, 23:59',
    );
  });

  test('a copy on offer says what it holds', () {
    final offer = CopyOffer(
      fileName: 'birka-2026-10-28.birka',
      copy: LedgerCopy.parse(
        sampleCopy(madeAt: DateTime(2026, 10, 28, 21, 40), operations: 5),
      ),
    );

    expect(
      offerLabel(offer, now: now),
      '28\u00A0октября, 21:40 · 5 операций · 1 счёт',
    );
  });

  test('every notice has words', () {
    final notices = [
      const CopySaved('birka-2026-11-02.birka'),
      CopyRestored(DateTime(2026, 10, 28, 21, 40)),
      const OperationsExported('birka-operations-2026-11-02.csv'),
      const LedgerWiped(),
      for (final problem in LedgerCopyProblem.values) CopyRefused(problem),
      const BackupFailed(),
    ];

    expect(
      [for (final it in notices) noticeLabel(it, now: now)],
      [
        'Копия готова: birka-2026-11-02.birka',
        'Записи восстановлены из копии от 28\u00A0октября',
        'Файл готов: birka-operations-2026-11-02.csv',
        'Все данные удалены с этого устройства',
        'Это не копия Birka.',
        [
          'Эту копию сделала более новая версия Birka.',
          'Обновите приложение и попробуйте снова.',
        ].join(' '),
        'Копия повреждена, её не получится восстановить.',
        'Не получилось. Попробуйте ещё раз.',
      ],
    );
    expect(notices.where((it) => it.isTrouble), hasLength(4));
  });

  test('the files are named after the day of the device', () {
    final moment = DateTime(2026, 11, 2, 21, 40);

    expect(copyFileName(moment.toUtc()), 'birka-2026-11-02.birka');
    expect(operationsFileName(moment), 'birka-operations-2026-11-02.csv');
  });
}
