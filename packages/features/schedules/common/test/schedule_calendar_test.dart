import 'package:ledger/ledger.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_common/testing.dart';
import 'package:test/test.dart';

void main() {
  SchedulesView viewOn(CivilDate today, List<Schedule> schedules) =>
      SchedulesView(
        today: today,
        schedules: schedules,
        accounts: const [],
        categories: const {},
        base: null,
        settings: const PaydaySettings(),
        todays: const [],
      );

  test('windows include both civil bounds across New Year in stable order', () {
    final today = CivilDate(2026, 12, 29);
    final view = viewOn(today, [
      for (final offset in [90, 89, 30, 29, 7, 6, 0])
        schedule(
          'bill-$offset',
          'Annual bill',
          10,
          today.addDays(offset),
          every: ScheduleEvery.year,
          onDay: ScheduleOnDay.post,
        ),
      schedule(
        'another',
        'Annual bill',
        10,
        today.addDays(6),
        every: ScheduleEvery.year,
      ),
    ]);
    List<String> ids(ScheduleWindow window) => [
      for (final it in view.calendar(window)) it.schedule.id,
    ];
    expect(ids(ScheduleWindow.week), ['bill-0', 'another', 'bill-6']);
    expect(ids(ScheduleWindow.month), [
      ...ids(ScheduleWindow.week),
      'bill-7',
      'bill-29',
    ]);
    expect(ids(ScheduleWindow.quarter), [
      ...ids(ScheduleWindow.month),
      'bill-30',
      'bill-89',
    ]);
    expect(view.ahead, view.calendar(ScheduleWindow.month));
  });

  test(
    'waiting is separate and month-end and advance dates follow the schedule',
    () {
      final today = CivilDate(2027, 1, 31);
      final salary = halvesRepository().schedules.singleWhere(
        (s) => s.id == 'pay',
      );
      final view = viewOn(today, [
        schedule('rent', 'Rent', 50, today),
        salary.movedTo(CivilDate(2027, 2, 5)),
      ]);
      final rows = view.calendar(ScheduleWindow.quarter);
      expect(view.waiting.map((s) => s.id), ['rent']);
      expect(rows.where((r) => r.schedule.id == 'rent').map((r) => r.on), [
        CivilDate(2027, 2, 28),
        CivilDate(2027, 3, 31),
        CivilDate(2027, 4, 30),
      ]);
      expect(rows.where((r) => r.schedule.id == 'pay').map((r) => r.on), [
        for (final month in [2, 3, 4]) ...[
          CivilDate(2027, month, 5),
          CivilDate(2027, month, 20),
        ],
      ]);
    },
  );
  test('midnight keeps the period and number of revealed dates', () async {
    final repository = FakeSchedulesRepository(
      schedules: [
        for (final id in ['a', 'b', 'c'])
          schedule(
            id,
            id,
            10,
            boardToday.addDays(1),
            every: ScheduleEvery.week,
          ),
      ],
    );
    final cubit = SchedulesCubit(repository);
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((s) => s is SchedulesLoaded);
    cubit
      ..selectWindow(ScheduleWindow.quarter)
      ..showMoreOccurrences();
    repository.day = boardToday.addDays(1);
    final updated = cubit.stream.firstWhere(
      (s) => s is SchedulesLoaded && s.view.today == repository.day,
    );
    await cubit.calendarChecked();
    final state = await updated as SchedulesLoaded;
    expect(state.window, ScheduleWindow.quarter);
    expect(state.visibleCount, 40);
    expect(state.view.waiting, hasLength(3));
    expect(state.visibleOccurrences.first.on, repository.day.addDays(7));
  });
}
