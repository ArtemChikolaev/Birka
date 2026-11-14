import 'package:debts_common/debts_common.dart';
import 'package:debts_common/testing.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:test/test.dart';

/// Lets the streams of the fake come in.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ru));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('the list', () {
    test('puts who owes whom apart and adds them up in rubles', () async {
      final cubit = DebtsCubit(FakeDebtsRepository());
      addTearDown(cubit.close);
      await settle();
      final state = cubit.state;

      expect(state.status, DebtsStatus.ready);
      expect(state.owed.map((debt) => debt.name), ['Дима', 'Маша']);
      expect(state.mine.map((debt) => debt.name), ['Саша']);
      expect(state.closed.map((debt) => debt.name), ['Ира', 'Папа']);
      expect(state.owedTotal, rub(12768));
      expect(state.mineTotal, rub(4000));
      expect(state.hasOtherCurrencies, isTrue);
      expect(
        debtsMoreLine(state),
        'Мне должны ${nb('12 768 ₽')} · мои ${nb('4 000 ₽')}',
      );
    });

    test('says when each debt is due and what is left of what', () async {
      final cubit = DebtsCubit(FakeDebtsRepository());
      addTearDown(cubit.close);
      await settle();
      final state = cubit.state;
      final [dima, masha] = state.owed;
      final [ira, dad] = state.closed;

      expect(debtLine(dima, today: boardToday), (
        text: 'срок сегодня',
        tone: DebtTone.due,
      ));
      expect(debtAmount(dima.left), nb(r'120 $'));
      expect(debtAmountNote(dima, state), '≈ ${nb('9 768 ₽')}');
      expect(debtLine(masha, today: boardToday).text, 'до 1 декабря');
      expect(debtAmountNote(masha, state), 'из ${nb('5 000 ₽')}');
      expect(
        debtLine(state.mine.single, today: boardToday).text,
        'до 20 ноября',
      );
      expect(debtAmountNote(state.mine.single, state), isNull);
      expect(debtLine(ira, today: boardToday), (
        text: 'вернули 2 ноября',
        tone: DebtTone.muted,
      ));
      expect(debtLine(dad, today: boardToday).text, 'вернули 30 октября');
    });

    test('says what the page is for without debts', () async {
      final cubit = DebtsCubit(
        FakeDebtsRepository(debts: [], transfers: []),
      );
      addTearDown(cubit.close);
      await settle();

      expect(cubit.state.isEmpty, isTrue);
      expect(debtsMoreLine(cubit.state), 'Кто кому должен и до какого дня');
    });

    test('fails when the debts cannot be read', () async {
      final cubit = DebtsCubit(FakeDebtsRepository(failing: true));
      addTearDown(cubit.close);
      await settle();

      expect(cubit.state.status, DebtsStatus.failed);
    });
  });

  group('the card', () {
    test('says what came back and when the day comes', () async {
      final cubit = DebtsCubit(FakeDebtsRepository());
      addTearDown(cubit.close);
      await settle();
      final masha = cubit.state.debt('masha')!;
      final sasha = cubit.state.debt('sasha')!;

      expect(
        debtLeftLine(masha, today: boardToday),
        'осталось вернуть вам из ${nb('5 000 ₽')}',
      );
      expect(debtSettledTitle(masha), 'Вернули ${nb('2 000 ₽')}');
      expect(debtShare(masha), '40%');
      expect(
        debtDueLine(masha, today: boardToday, reminders: true).text,
        'Срок 1 декабря · напомним в этот день',
      );
      expect(
        debtDueLine(masha, today: boardToday, reminders: false).text,
        'Срок 1 декабря · через 17 дней',
      );
      expect(
        debtLeftLine(sasha, today: boardToday),
        'осталось отдать из ${nb('4 000 ₽')}',
      );
      expect(debtSettledTitle(sasha), 'Отдали ${nb('0 ₽')}');
      expect(
        debtDueLine(sasha, today: boardToday, reminders: true).text,
        'Срок 20 ноября · через 6 дней',
      );
      final back = masha.steps.first;
      expect(debtStepTitle(back), 'Возврат');
      expect(
        debtStepLine(back, today: boardToday),
        '10 ноября · Зарплатная карта',
      );
      expect(debtStepAmount(back), '+${nb('2 000 ₽')}');
      expect(
        debtStepLine(masha.steps.last, today: boardToday),
        '3 ноября · Наличные · на билеты',
      );
    });
  });

  group('the form', () {
    test('lends to a new person and says what it wrote', () async {
      final repository = FakeDebtsRepository();
      final form = DebtFormCubit(repository);
      addTearDown(form.close);
      await settle();

      expect(form.state.status, DebtFormStatus.editing);
      expect(
        [for (final person in form.state.chips) person.name],
        ['Маша', 'Саша', 'Ира', 'Папа', 'Дима'],
      );
      form
        ..nameChanged('Лена')
        ..accountChanged('cash')
        ..amountChanged(250000)
        ..dueChanged(CivilDate(2026, 11, 30))
        ..noteChanged('на концерт');
      expect(form.state.match, isNull);
      expect(form.state.reminds, isTrue);
      expect(form.state.offered, hasLength(3));
      await form.save();

      expect(form.state.status, DebtFormStatus.saved);
      expect(
        debtSavedToast(form.state.saved!),
        'Записали: Лена, ${nb('2 500 ₽')}',
      );
      final lena = repository.debts.last;
      expect(lena.name, 'Лена');
      expect(
        lena.debt,
        DebtTerms(
          side: DebtSide.lent,
          dueOn: CivilDate(2026, 11, 30),
          reminds: true,
        ),
      );
      final lent = repository.transfers.last;
      expect(lent.entries.first.accountId, 'cash');
      expect(lent.entries.last.accountId, lena.id);
      expect(lent.note, 'на концерт');
    });

    test(
      'lends more to a person and keeps to the currency of the debt',
      () async {
        final repository = FakeDebtsRepository();
        final form = DebtFormCubit(repository);
        addTearDown(form.close);
        await settle();

        form.personPicked(form.state.chips.last);
        expect(form.state.match?.id, 'dima');
        expect(form.state.offered.map((row) => row.account.id), ['savings']);
        expect(form.state.accountId, 'savings');
        expect(form.state.dueOn, boardToday);
        expect(form.state.currency, Currency.usd);

        form.amountChanged(5000);
        await form.save();
        expect(repository.transfers.last.entries.last.accountId, 'dima');
      },
    );

    test('borrows from the person of a card that is fixed to it', () async {
      final repository = FakeDebtsRepository();
      final form = DebtFormCubit(
        repository,
        debtId: 'sasha',
      );
      addTearDown(form.close);
      await settle();

      expect(form.state.side, DebtSide.borrowed);
      expect(form.state.name, 'Саша');
      form
        ..sideChanged(DebtSide.lent)
        ..nameChanged('Маша');
      expect(form.state.side, DebtSide.borrowed);
      expect(form.state.name, 'Саша');

      form
        ..accountChanged('card')
        ..amountChanged(100000);
      await form.save();
      final borrowed = repository.transfers.last;
      expect(borrowed.entries.first.accountId, 'sasha');
      expect(borrowed.entries.last.accountId, 'card');
    });

    test('asks for a name before it saves', () async {
      final form = DebtFormCubit(FakeDebtsRepository());
      addTearDown(form.close);
      await settle();

      form.amountChanged(1000);
      await form.save();
      expect(form.state.nameMissing, isTrue);
      expect(form.state.status, DebtFormStatus.editing);
    });

    test('says when no account is in the currency of the debt', () async {
      final form = DebtFormCubit(
        FakeDebtsRepository(
          accounts: [own('card', 'Зарплатная карта', Currency.rub)],
        ),
      );
      addTearDown(form.close);
      await settle();

      form.personPicked(form.state.chips.last);
      expect(form.state.noAccount, isTrue);
      expect(form.state.canSave, isFalse);
    });
  });

  group('the people', () {
    // The person lent 500 ₽ to Иван, a neighbour, on 1 November.
    FakeDebtsRepository neighbour() => FakeDebtsRepository(
      debts: [
        debtAccount('ivan', 'Иван', DebtSide.lent, personId: 'p-ivan'),
      ],
      people: [const Person(id: 'p-ivan', name: 'Иван', about: 'сосед')],
      transfers: [
        transfer('ivan-lent', 'card', 'ivan', rub(500), CivilDate(2026, 11, 1)),
      ],
    );

    test('a chip picks the person, and a typed name is someone new', () async {
      final form = DebtFormCubit(neighbour());
      addTearDown(form.close);
      await settle();

      form.personPicked(form.state.chips.single);
      expect(form.state.match?.id, 'ivan');
      expect(form.state.about, 'сосед');
      expect(form.state.twin, isNull);

      form.nameChanged('Иван');
      expect(form.state.personId, isNull);
      expect(form.state.match, isNull);
      expect(form.state.about, '');
      expect(form.state.twin?.about, 'сосед');
      expect(
        debtTwinLine(form.state.twin!),
        'Иван уже есть — сосед. Напишите, кто это, чтобы их различать.',
      );
    });

    test('someone new keeps who they are and their number', () async {
      final repository = neighbour();
      final form = DebtFormCubit(repository);
      addTearDown(form.close);
      await settle();

      form
        ..nameChanged(' Иван ')
        ..aboutChanged('коллега из бухгалтерии')
        ..phoneChanged(' +7 999 123-45-67 ')
        ..accountChanged('card')
        ..amountChanged(200000);
      await form.save();

      final colleague = repository.people.last;
      expect(colleague.name, 'Иван');
      expect(colleague.about, 'коллега из бухгалтерии');
      expect(colleague.phone, '+7 999 123-45-67');
      expect(repository.debts.last.personId, colleague.id);
      expect(repository.debts.first.personId, 'p-ivan');
      expect(
        [
          for (final person in repository.people)
            debtPersonLabel(person, repository.people),
        ],
        ['Иван · сосед', 'Иван · коллега из бухгалтерии'],
      );
    });

    test('the terms change the person of every debt of theirs', () async {
      final repository = neighbour();
      final terms = DebtTermsCubit(repository, 'ivan');
      addTearDown(terms.close);
      await settle();

      expect(terms.state.about, 'сосед');
      terms
        ..nameChanged('Ваня')
        ..aboutChanged('сосед с 5 этажа')
        ..phoneChanged('+7 999 765-43-21');
      await terms.save();

      expect(
        repository.people.single,
        const Person(
          id: 'p-ivan',
          name: 'Ваня',
          about: 'сосед с 5 этажа',
          phone: '+7 999 765-43-21',
        ),
      );
      expect(repository.debts.single.name, 'Ваня');
    });
  });

  group('the return', () {
    test('takes back all that is left and settles the debt', () async {
      final repository = FakeDebtsRepository();
      final form = DebtReturnCubit(repository, 'masha');
      addTearDown(form.close);
      await settle();

      expect(form.state.status, DebtReturnStatus.editing);
      expect(form.state.accountId, 'card');
      expect(debtReturnTitle(form.state.debt!), 'Возврат · Маша');
      expect(debtReturnAll(form.state.debt!), 'Всё · ${nb('3 000 ₽')}');
      expect(
        debtReturnCaption(form.state, reminders: true),
        'Долг закроется, и напоминание о нём уйдёт. Деньги придут на счёт, '
        'но не в доходы.',
      );
      await form.save();

      expect(form.state.status, DebtReturnStatus.saved);
      expect(debtReturnedToast(form.state.saved!), 'Маша: долг закрыт');
      final back = repository.transfers.last;
      expect(back.entries.first.accountId, 'masha');
      expect(back.entries.last.amount, rub(3000));
    });

    test('takes back a part and says what is left', () async {
      final form = DebtReturnCubit(FakeDebtsRepository(), 'masha');
      addTearDown(form.close);
      await settle();

      form
        ..allChanged(all: false)
        ..partChanged(400000);
      expect(form.state.tooMuch, isTrue);
      expect(form.state.canSave, isFalse);

      form.partChanged(100000);
      expect(
        debtReturnCaption(form.state, reminders: false),
        'Останется ${nb('2 000 ₽')} до 1 декабря. Деньги придут на счёт, '
        'но не в доходы.',
      );
      await form.save();
      expect(
        debtReturnedToast(form.state.saved!),
        'Возврат ${nb('1 000 ₽')} · осталось ${nb('2 000 ₽')}',
      );
    });

    test('gives back what the person owes', () async {
      final repository = FakeDebtsRepository();
      final form = DebtReturnCubit(repository, 'sasha');
      addTearDown(form.close);
      await settle();

      expect(debtReturnTitle(form.state.debt!), 'Отдать · Саша');
      form
        ..allChanged(all: false)
        ..partChanged(100000);
      await form.save();
      expect(
        debtReturnedToast(form.state.saved!),
        'Отдали ${nb('1 000 ₽')} · осталось ${nb('3 000 ₽')}',
      );
      final repaid = repository.transfers.last;
      expect(repaid.entries.first.accountId, 'card');
      expect(repaid.entries.last.accountId, 'sasha');
    });

    test('of a settled debt has nothing to take back', () async {
      final form = DebtReturnCubit(FakeDebtsRepository(), 'ira');
      addTearDown(form.close);
      await settle();

      expect(form.state.status, DebtReturnStatus.gone);
    });
  });

  group('the terms', () {
    test('rename a debt and move its day', () async {
      final repository = FakeDebtsRepository();
      final form = DebtTermsCubit(repository, 'sasha');
      addTearDown(form.close);
      await settle();

      expect(form.state.name, 'Саша');
      expect(form.state.reminds, isFalse);
      form
        ..nameChanged('Саша Н.')
        ..dueChanged(CivilDate(2026, 11, 25));
      expect(form.state.reminds, isFalse);
      form.remindsChanged(reminds: true);
      await form.save();

      expect(form.state.status, DebtTermsStatus.saved);
      final sasha = repository.debts.firstWhere((debt) => debt.id == 'sasha');
      expect(sasha.name, 'Саша Н.');
      expect(
        sasha.debt,
        DebtTerms(
          side: DebtSide.borrowed,
          dueOn: CivilDate(2026, 11, 25),
          reminds: true,
        ),
      );
    });

    test('drop the reminder with the day', () async {
      final form = DebtTermsCubit(FakeDebtsRepository(), 'masha');
      addTearDown(form.close);
      await settle();

      expect(form.state.reminds, isTrue);
      form.dueChanged(null);
      expect(form.state.reminds, isFalse);
      form.remindsChanged(reminds: true);
      expect(form.state.reminds, isFalse);
    });
  });
}
