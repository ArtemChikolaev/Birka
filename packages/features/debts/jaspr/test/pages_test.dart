import 'package:debts_common/debts_common.dart';
import 'package:debts_common/testing.dart';
import 'package:debts_jaspr/debts_jaspr.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// Where the link around [text] leads.
String? hrefOf(String text) =>
    (find
                .ancestor(of: find.text(text), matching: find.tag('a'))
                .evaluate()
                .first
                .component
            as DomComponent)
        .attributes?['href'];

/// The text input under the label that says [label].
input<String> field(String label) =>
    find
            .descendant(
              of: find.ancestor(
                of: find.text(label),
                matching: find.tag('label'),
              ),
              matching: find.byType(input<String>),
            )
            .evaluate()
            .single
            .component
        as input<String>;

/// The button that says [text].
Finder buttonOf(String text) =>
    find.ancestor(of: find.text(text), matching: find.tag('button')).first;

/// Whether the fold around [text] stands open.
bool foldOf(String text) =>
    (find
                .ancestor(of: find.text(text), matching: find.byType(BirkaFold))
                .evaluate()
                .first
                .component
            as BirkaFold)
        .open;

void main() {
  setUp(() {
    setIsClientForTesting(true);
    LocaleSettings.setLocaleSync(AppLocale.ru);
  });
  tearDown(() {
    resetIsClientForTesting();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  group('the list', () {
    testComponents('adds up who owes whom and leads to each person', (
      tester,
    ) async {
      final cubit = DebtsCubit(FakeDebtsRepository());
      addTearDown(cubit.close);
      tester.pumpComponent(
        BlocProvider<DebtsCubit>.value(
          value: cubit,
          child: DebtsPage(
            addHref: 'debts/#new',
            hrefOf: (id) => 'debts/#$id',
            picked: 'masha',
            side: const p([.text('beside')]),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(nb('12 768 ₽')), findsOneComponent);
      expect(find.text('2 человека'), findsOneComponent);
      expect(find.text('Мне должны'), findsNComponents(2));
      expect(find.text('срок сегодня'), findsOneComponent);
      expect(find.text('≈ ${nb('9 768 ₽')}'), findsOneComponent);
      expect(find.text('из ${nb('5 000 ₽')}'), findsOneComponent);
      expect(hrefOf('Маша'), 'debts/#masha');
      expect(hrefOf('Саша'), 'debts/#sasha');
      expect(find.text('beside'), findsOneComponent);
      expect(foldOf('Ира'), isFalse);

      await tester.click(buttonOf('Закрытые · 2'));
      await tester.pump();
      expect(foldOf('Ира'), isTrue);
      expect(find.text('вернули 2 ноября'), findsOneComponent);
    });

    testComponents('offers the first debt when there is none', (tester) async {
      final cubit = DebtsCubit(FakeDebtsRepository(debts: [], transfers: []));
      addTearDown(cubit.close);
      tester.pumpComponent(
        BlocProvider<DebtsCubit>.value(
          value: cubit,
          child: DebtsPage(addHref: 'debts/#new', hrefOf: (id) => id),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Долгов нет'), findsOneComponent);
      expect(hrefOf('Записать долг'), 'debts/#new');
    });
  });

  testComponents('the card opens its return in a fold and gives back what a '
      'return wrote', (tester) async {
    final repository = FakeDebtsRepository();
    final debts = DebtsCubit(repository);
    addTearDown(debts.close);
    final returned = <DebtReturned>[];
    tester.pumpComponent(
      BlocProvider<DebtsCubit>.value(
        value: debts,
        child: DebtPage(
          id: 'masha',
          onBack: () {},
          editHref: 'debts/#edit-masha',
          moreHref: 'debts/#more-masha',
          hrefOfOperation: (id) => 'operations/#$id',
          returnForm: (close) => BlocProvider<DebtReturnCubit>(
            create: (_) => DebtReturnCubit(repository, 'masha'),
            child: DebtReturnForm(
              onDone: (it) {
                returned.add(it);
                close();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(nb('3 000 ₽')), findsOneComponent);
    expect(
      find.text('осталось вернуть вам из ${nb('5 000 ₽')}'),
      findsOneComponent,
    );
    expect(find.text('Вернули ${nb('2 000 ₽')}'), findsOneComponent);
    expect(find.text('Срок 1 декабря · через 17 дней'), findsOneComponent);
    expect(hrefOf('Ещё в долг'), 'debts/#more-masha');
    expect(hrefOf('Изменить'), 'debts/#edit-masha');
    expect(hrefOf('10 ноября · Зарплатная карта'), 'operations/#masha-back');

    await tester.click(buttonOf('Возврат'));
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
    expect(find.text('Сколько вернули'), findsOneComponent);
    await tester.click(buttonOf('Часть'));
    await tester.pump();
    field('Сумма').onInput!('1000');
    await tester.pump();
    expect(
      find.text(
        'Останется ${nb('2 000 ₽')} до 1 декабря. Деньги придут на счёт, '
        'но не в доходы.',
      ),
      findsOneComponent,
    );

    await tester.click(buttonOf('Сохранить возврат'));
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
    expect(returned.single.amount, rub(1000));
    expect(returned.single.left, rub(2000));
    expect(find.text('Сколько вернули'), findsNothing);
    expect(find.text(nb('2 000 ₽')), findsOneComponent);
  });

  testComponents('the form lends to someone new and gives back what it '
      'wrote', (tester) async {
    final repository = FakeDebtsRepository();
    final cubit = DebtFormCubit(repository, reminders: false);
    addTearDown(cubit.close);
    final saved = <DebtSaved>[];
    tester.pumpComponent(
      BlocProvider<DebtFormCubit>.value(
        value: cubit,
        child: DebtFormPage(onClose: () {}, onDone: saved.add),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Новый долг'), findsOneComponent);
    expect(find.text('Маша'), findsOneComponent);
    field('Кто').onInput!('Лена');
    field('Сумма').onInput!('2 500');
    await tester.pump();
    expect(cubit.state.canSave, isTrue);
    expect(cubit.state.reminds, isFalse);

    await cubit.save();
    await tester.pump();

    expect(saved.single.name, 'Лена');
    expect(saved.single.amount, rub(2500));
    expect(repository.debts.last.name, 'Лена');
  });

  testComponents('the terms rename the person and keep the reminder of a '
      'phone', (tester) async {
    final repository = FakeDebtsRepository();
    final cubit = DebtTermsCubit(repository, 'masha', reminders: false);
    addTearDown(cubit.close);
    var done = 0;
    tester.pumpComponent(
      BlocProvider<DebtTermsCubit>.value(
        value: cubit,
        child: DebtTermsPage(onClose: () {}, onDone: () => done++),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Изменить долг'), findsOneComponent);
    field('Имя').onInput!('Маша К.');
    await tester.pump();
    await cubit.save();
    await tester.pump();

    expect(done, 1);
    final masha = repository.debts.firstWhere((debt) => debt.id == 'masha');
    expect(masha.name, 'Маша К.');
    expect(masha.debt?.reminds, isTrue);
    expect(masha.debt?.side, DebtSide.lent);
  });

  group('the people', () {
    const number = '+7 999 123-45-67';

    /// The people of the boards, with who Маша is and her [phone].
    List<Person> people({String? phone}) => [
      for (final person in peopleOf(boardDebts()))
        person.id == 'p-masha'
            ? person.copyWith(about: 'коллега', phone: () => phone)
            : person,
    ];

    Future<void> card(
      ComponentTester tester,
      String id, {
      required List<Person> people,
      Future<void> Function(String text)? onCopy,
    }) async {
      final debts = DebtsCubit(FakeDebtsRepository(people: people));
      addTearDown(debts.close);
      tester.pumpComponent(
        BlocProvider<DebtsCubit>.value(
          value: debts,
          child: DebtPage(
            id: id,
            onBack: () {},
            editHref: 'debts/#edit-$id',
            moreHref: 'debts/#more-$id',
            hrefOfOperation: (id) => 'operations/#$id',
            onCopy: onCopy,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testComponents('the card says who it is and copies a reminder', (
      tester,
    ) async {
      final copied = <String>[];
      await card(
        tester,
        'masha',
        people: people(phone: number),
        onCopy: (text) async => copied.add(text),
      );

      expect(find.text('коллега'), findsOneComponent);
      expect(find.text('Скопировать текст'), findsNothing);
      await tester.click(buttonOf('Напомнить'));
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }

      final text =
          'Привет! Напоминаю про ${nb('3 000 ₽')} — договаривались вернуть '
          'до 1 декабря.';
      expect(find.text(text), findsOneComponent);
      expect(find.text(number), findsOneComponent);
      expect(
        find.text(
          'Сайт сам ничего не отправляет: скопируйте текст и вставьте его '
          'в мессенджер или SMS.',
        ),
        findsOneComponent,
      );
      (find.byType(textarea).evaluate().single.component as textarea).onInput!(
        '$text Спасибо!',
      );
      await tester.click(buttonOf('Скопировать текст'));
      await tester.pump();
      expect(copied, ['$text Спасибо!']);

      // The return takes the place of the reminder.
      await tester.click(buttonOf('Возврат'));
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }
      expect(find.text('Скопировать текст'), findsNothing);
    });

    testComponents('a reminder without a number asks for one', (tester) async {
      await card(
        tester,
        'masha',
        people: people(),
        onCopy: (_) async {},
      );
      await tester.click(buttonOf('Напомнить'));
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }
      expect(
        find.text('Номера нет · добавьте в «Изменить»'),
        findsOneComponent,
      );
    });

    testComponents('a debt of the person has no reminder', (tester) async {
      await card(
        tester,
        'sasha',
        people: people(phone: number),
        onCopy: (_) async {},
      );
      expect(find.text('Напомнить'), findsNothing);
    });

    testComponents('the form folds in who someone new is', (tester) async {
      final cubit = DebtFormCubit(
        FakeDebtsRepository(people: people(phone: number)),
        reminders: false,
      );
      addTearDown(cubit.close);
      tester.pumpComponent(
        BlocProvider<DebtFormCubit>.value(
          value: cubit,
          child: DebtFormPage(onClose: () {}, onDone: (_) {}),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(foldOf('Кто это'), isFalse);
      field('Кто').onInput!('маша');
      await tester.pump();
      expect(foldOf('Кто это'), isTrue);
      const twin =
          'Маша уже есть — коллега. Если это тот же человек, выберите его '
          'выше; если другой — напишите, кто это.';
      expect(find.text(twin), findsOneComponent);

      field('Кто это').onInput!('сестра');
      field('Телефон').onInput!('+7 900 000-00-00');
      await tester.pump();
      expect(find.text(twin), findsNothing);
      expect(
        (cubit.state.about, cubit.state.phone),
        ('сестра', '+7 900 000-00-00'),
      );

      await tester.click(buttonOf('Маша'));
      await tester.pump();
      expect(foldOf('Кто это'), isFalse);
      expect(cubit.state.personId, 'p-masha');
    });

    testComponents('the terms change who it is and the number', (
      tester,
    ) async {
      final repository = FakeDebtsRepository();
      final cubit = DebtTermsCubit(repository, 'sasha', reminders: false);
      addTearDown(cubit.close);
      tester.pumpComponent(
        BlocProvider<DebtTermsCubit>.value(
          value: cubit,
          child: DebtTermsPage(onClose: () {}, onDone: () {}),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text(
          'Имя, «кто это» и номер — общие для всех долгов этого человека. '
          'Номер хранится только в этом браузере и в ваших копиях.',
        ),
        findsOneComponent,
      );
      field('Кто это').onInput!('брат');
      field('Телефон').onInput!('+7 900 000-00-00');
      await tester.pump();
      await cubit.save();
      await tester.pump();

      final person = repository.people.firstWhere((it) => it.id == 'p-sasha');
      expect((person.about, person.phone), ('брат', '+7 900 000-00-00'));
    });
  });
}
