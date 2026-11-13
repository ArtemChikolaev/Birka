import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:tags_common/tags_common.dart';
import 'package:tags_common/testing.dart';
import 'package:test/test.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('the list puts each метка on its shelf with what it took', () async {
    final cubit = TagsCubit(FakeTagsRepository());
    addTearDown(cubit.close);

    final state = await cubit.stream.firstWhere(
      (it) => it.status == TagsStatus.ready,
    );

    expect([for (final it in state.on(TagShelf.now)) it.tag.id], ['tbilisi']);
    expect(
      [for (final it in state.on(TagShelf.trips)) it.tag.id],
      [
        'istanbul',
      ],
    );
    expect(
      [for (final it in state.on(TagShelf.plain)) it.tag.id],
      [
        'renovation',
      ],
    );
    expect(state.on(TagShelf.now).single.total.minorUnits, 6201500);
  });

  test('the report of a метка that goes is gone', () async {
    final cubit = TagReportCubit(FakeTagsRepository(), 'nope');
    addTearDown(cubit.close);

    final state = await cubit.stream.firstWhere(
      (it) => it.status != TagReportStatus.loading,
    );

    expect(state.status, TagReportStatus.gone);
  });

  group('the form', () {
    test('of a new trip counts the expenses its days already have', () async {
      final repository = FakeTagsRepository()..toMark = 14;
      final cubit = TagFormCubit(repository, name: ' Казань ');
      addTearDown(cubit.close);

      final state = await cubit.stream.firstWhere((it) => it.toMark == 14);

      expect(state.name, 'Казань');
      expect(state.trip, isTrue);
      expect(state.days, TagDays(boardToday, boardToday.addDays(2)));
    });

    test('needs a name', () async {
      final cubit = TagFormCubit(FakeTagsRepository());
      addTearDown(cubit.close);

      await cubit.save();

      expect(cubit.state.nameMissing, isTrue);
      expect(cubit.state.status, TagFormStatus.editing);
    });

    test('saves a trip with its days and says what it marked', () async {
      final repository = FakeTagsRepository()..toMark = 14;
      final cubit = TagFormCubit(repository)
        ..nameChanged('Казань')
        ..daysChanged(CivilDate(2026, 9, 20), CivilDate(2026, 9, 18));

      await cubit.save();
      await cubit.undo();
      await cubit.close();

      final saved = cubit.state.saved!;
      expect(cubit.state.status, TagFormStatus.saved);
      expect(saved.marked, 14);
      // A last day before the first moves to it.
      expect(
        saved.tag.days,
        TagDays(CivilDate(2026, 9, 20), CivilDate(2026, 9, 20)),
      );
      expect(repository.unmarked, [saved.tag.id]);
    });

    test('saves a метка without days that marks nothing', () async {
      final repository = FakeTagsRepository()..toMark = 14;
      final cubit = TagFormCubit(repository)
        ..nameChanged('Новый год')
        ..tripChanged(trip: false);

      await cubit.save();
      await cubit.close();

      final saved = cubit.state.saved!;
      expect(saved.tag.days, isNull);
      expect(saved.tag.marksDays, isFalse);
      expect(saved.marked, 0);
    });

    test('of a метка that is there starts from it', () async {
      final cubit = TagFormCubit(FakeTagsRepository(), id: 'istanbul');
      addTearDown(cubit.close);

      final state = await cubit.stream.firstWhere(
        (it) => it.status == TagFormStatus.editing,
      );

      expect(state.name, 'Стамбул');
      expect(state.days, istanbul.days);
      expect(state.isNew, isFalse);
    });
  });

  group('the picker', () {
    test('finds метки by a part of the name and offers to make one', () async {
      final cubit = TagPickerCubit(FakeTagsRepository(), picked: {'tbilisi'});
      addTearDown(cubit.close);
      await cubit.stream.firstWhere((it) => it.tags != null);

      expect(
        [for (final tag in cubit.state.trips) tag.id],
        [
          'tbilisi',
          'istanbul',
        ],
      );
      expect(cubit.state.canCreate, isFalse);

      cubit.queryChanged('ремонт');

      expect(cubit.state.trips, isEmpty);
      expect([for (final tag in cubit.state.plain) tag.id], ['renovation']);
      expect(cubit.state.canCreate, isTrue);

      cubit.queryChanged('Ремонт кухни ');

      expect(cubit.state.canCreate, isFalse);
    });

    test('picks and lets go, and picks what the form made', () async {
      final cubit = TagPickerCubit(FakeTagsRepository(), picked: {'tbilisi'})
        ..toggle('tbilisi')
        ..toggle('renovation')
        ..queryChanged('Батуми')
        ..created('batumi');
      addTearDown(cubit.close);

      expect(cubit.state.picked, {'renovation', 'batumi'});
      expect(cubit.state.query, isEmpty);
    });

    test('makes a метка of the search where no form opens', () async {
      final repository = FakeTagsRepository();
      final cubit = TagPickerCubit(repository, picked: {'tbilisi'});
      addTearDown(cubit.close);
      await cubit.stream.firstWhere((it) => it.tags != null);

      cubit.queryChanged('Ремонт кухни');
      expect(await cubit.create(), isNull);

      cubit.queryChanged(' Свадьба Кати ');
      final id = await cubit.create();

      final made = await repository.watchTags().first;
      expect(made.last.name, 'Свадьба Кати');
      expect(made.last.days, isNull);
      expect(id, made.last.id);
      expect(cubit.state.picked, {'tbilisi', id});
      expect(cubit.state.query, isEmpty);
    });
  });

  test('the card of an operation lists its метки, the trips first', () async {
    final repository = FakeTagsRepository(
      operations: [
        expense(
          'lunch',
          units(38, gel),
          boardToday,
          tags: {
            'renovation': TagMark.hand,
            'tbilisi': TagMark.days,
            'istanbul': TagMark.off,
          },
        ),
      ],
    );
    final cubit = OperationTagsCubit(repository, 'lunch');
    addTearDown(cubit.close);

    final state = await cubit.stream.firstWhere((it) => it.read);
    await cubit.pick({'renovation'});

    expect(
      [for (final it in state.worn) (it.tag.id, it.mark)],
      [
        ('tbilisi', TagMark.days),
        ('renovation', TagMark.hand),
      ],
    );
    expect(state.can, isTrue);
    expect(repository.picked, {
      'lunch': {'renovation'},
    });
  });

  test('the card writes nothing for the метки it already wears', () async {
    final repository = FakeTagsRepository();
    final cubit = OperationTagsCubit(repository, 'lunch');
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((it) => it.read);

    await cubit.pick({'tbilisi'});

    expect(repository.picked, isEmpty);
  });
}
