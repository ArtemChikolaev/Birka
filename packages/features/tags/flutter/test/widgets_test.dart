import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:tags_common/tags_common.dart';
import 'package:tags_common/testing.dart';
import 'package:tags_flutter/tags_flutter.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  void phoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('the picker of метки', () {
    /// Opens the picker with [cubit] over a page, and gives what it closes
    /// with once it does.
    Future<Future<Set<String>>> open(
      WidgetTester tester,
      TagPickerCubit cubit, {
      Future<String?> Function(BuildContext, String)? onCreate,
    }) async {
      late Future<Set<String>> closed;
      await tester.pumpWidget(
        MaterialApp(
          theme: BirkaTheme.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => closed = showTagPicker(
                    context,
                    cubit: cubit,
                    onCreate: onCreate ?? (_, _) async => null,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return closed;
    }

    testWidgets('puts the trip of today first and picks with a tap', (
      tester,
    ) async {
      phoneSize(tester);
      final cubit = TagPickerCubit(
        FakeTagsRepository(tags: [istanbul, renovation, tbilisi]),
        picked: {'tbilisi'},
      );
      final closed = await open(tester, cubit);

      expect(find.text('ПОЕЗДКИ'), findsOneWidget);
      expect(find.text('МЕТКИ'), findsOneWidget);
      expect(find.text('3–12 ноября · сейчас'), findsOneWidget);
      expect(find.text('2–9 мая'), findsOneWidget);
      expect(top(tester, 'Тбилиси'), lessThan(top(tester, 'Стамбул')));
      expect(top(tester, 'Стамбул'), lessThan(top(tester, 'Ремонт кухни')));

      await tester.tap(find.text('Ремонт кухни'));
      await tester.tap(find.text('Тбилиси'));
      await tester.pump();

      expect(
        tester.widget<BirkaCheckbox>(find.byType(BirkaCheckbox).first).checked,
        isFalse,
      );

      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();

      expect(await closed, {'renovation'});
    });

    testWidgets('finds a метка and makes one of a new name', (tester) async {
      phoneSize(tester);
      final repository = FakeTagsRepository();
      final cubit = TagPickerCubit(repository);
      final asked = <String>[];
      final closed = await open(
        tester,
        cubit,
        onCreate: (_, name) async {
          asked.add(name);
          return (await repository.add(name: name)).tag.id;
        },
      );

      await tester.enterText(find.byType(TextField), 'стам');
      await tester.pump();

      expect(find.text('Стамбул'), findsOneWidget);
      expect(find.text('Тбилиси'), findsNothing);
      expect(find.text('МЕТКИ'), findsNothing);
      expect(find.text('Новая метка «стам»'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'стамбул');
      await tester.pump();

      expect(find.text('Стамбул'), findsOneWidget);
      expect(find.textContaining('Новая метка'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Казань ');
      await tester.pump();

      expect(find.text('Стамбул'), findsNothing);

      await tester.tap(find.text('Новая метка «Казань»'));
      await tester.pumpAndSettle();

      expect(asked, ['Казань']);
      expect(find.text('Казань'), findsOneWidget);
      expect(find.text('Тбилиси'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty,
      );

      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();

      expect(await closed, {'tag-3'});
    });

    testWidgets('with no метки asks for a name', (tester) async {
      phoneSize(tester);
      final cubit = TagPickerCubit(FakeTagsRepository(tags: []));
      final closed = await open(tester, cubit);

      expect(find.text('Меток пока нет'), findsOneWidget);
      expect(find.text('ПОЕЗДКИ'), findsNothing);

      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();

      expect(await closed, isEmpty);
    });
  });

  group('the метки on the card of an operation', () {
    Future<void> pump(
      WidgetTester tester,
      OperationTagsCubit cubit, {
      ValueChanged<String>? onOpen,
      Future<Set<String>?> Function(BuildContext, Set<String>)? onPick,
    }) async {
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: BirkaTheme.dark(),
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: ListView(
                children: [
                  OperationTagsRow(
                    onOpen: onOpen ?? (_) {},
                    onPick: onPick ?? (_, _) async => null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lead to the reports, the trip first', (tester) async {
      final opened = <String>[];
      final repository = FakeTagsRepository(
        operations: [
          expense(
            'dinner',
            Money(9600, gel),
            CivilDate(2026, 11, 11),
            tags: {
              'renovation': TagMark.hand,
              'tbilisi': TagMark.days,
              'istanbul': TagMark.off,
            },
          ),
        ],
      );
      await pump(
        tester,
        OperationTagsCubit(repository, 'dinner'),
        onOpen: opened.add,
      );

      expect(find.text('Поездка · 3–12 ноября · по датам'), findsOneWidget);
      expect(find.text('Метка'), findsOneWidget);
      expect(find.text('Стамбул'), findsNothing);
      expect(find.text('Добавить метку'), findsNothing);
      expect(top(tester, 'Тбилиси'), lessThan(top(tester, 'Ремонт кухни')));

      await tester.tap(find.text('Ремонт кухни'));

      expect(opened, ['renovation']);
    });

    testWidgets('of a trip put on by hand say so', (tester) async {
      await pump(
        tester,
        OperationTagsCubit(FakeTagsRepository(), 'flat'),
      );

      expect(find.text('Тбилиси'), findsOneWidget);
      expect(find.text('Поездка · 3–12 ноября'), findsOneWidget);
    });

    testWidgets('offer one to an operation without them', (tester) async {
      final asked = <Set<String>>[];
      final repository = FakeTagsRepository(
        operations: [
          expense('coffee', Money(30000, Currency.rub), boardToday),
        ],
      );
      await pump(
        tester,
        OperationTagsCubit(repository, 'coffee'),
        onPick: (_, picked) async {
          asked.add(picked);
          return {'renovation'};
        },
      );

      expect(find.text('Поездка, ремонт или праздник'), findsOneWidget);

      await tester.tap(find.text('Добавить метку'));
      await tester.pumpAndSettle();

      expect(asked, [<String>{}]);
      expect(repository.picked, {
        'coffee': {'renovation'},
      });
      expect(find.text('Ремонт кухни'), findsOneWidget);
      expect(find.text('Добавить метку'), findsNothing);
    });

    testWidgets('are not there for an operation that is gone', (tester) async {
      await pump(
        tester,
        OperationTagsCubit(FakeTagsRepository(), 'gone'),
      );

      expect(find.byType(GlassListRow), findsNothing);
    });
  });
}

double top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;
