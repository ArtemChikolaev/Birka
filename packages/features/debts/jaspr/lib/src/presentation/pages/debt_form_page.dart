import 'dart:async';

import 'package:debts_common/debts_common.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// The form of a new debt, or of more money on one (ADR 0029): whether the
/// person lends or borrows, who, how much, from or to which account, when,
/// by what day and a note. A name typed that no chip picks is someone new,
/// and folds in who they are and their number (ADR 0030). The site has no
/// reminders, so the form has no switch of them. Once saved, it gives what
/// it wrote to [onDone].
///
/// It needs a [DebtFormCubit] above it.
class DebtFormPage extends StatefulComponent {
  /// Creates the form.
  const DebtFormPage({required this.onClose, required this.onDone, super.key});

  /// Closes the form without a save.
  final VoidCallback onClose;

  /// Called once the debt is saved, with what the save wrote.
  final ValueChanged<DebtSaved> onDone;

  @override
  State<DebtFormPage> createState() => _DebtFormPageState();

  /// The styles of the form.
  @css
  static List<StyleRule> get styles => [
    css('.debt-form__who').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.debt-form__people').styles(
      raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': 'var(--space-xs)'},
    ),
    css('.debt-form__note').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    // Someone of the same name is there: who the new one is tells them apart.
    css('.debt-form__twin').styles(
      raw: {'color': 'var(--color-palette-amber)', 'margin': '0'},
    ),
  ];
}

class _DebtFormPageState extends State<DebtFormPage> {
  /// What the person typed as the amount, kept as typed.
  String? _amount;

  @override
  Component build(BuildContext context) {
    return BlocConsumer<DebtFormCubit, DebtFormState>(
      listenWhen: (before, now) => before.status != now.status,
      listener: (_, state) {
        final saved = state.saved;
        if (state.status == DebtFormStatus.saved && saved != null) {
          component.onDone(saved);
        }
      },
      builder: (context, state) => switch (state.status) {
        DebtFormStatus.loading => const div([]),
        _ => _form(context, state),
      },
    );
  }

  Component _form(BuildContext context, DebtFormState state) {
    final cubit = context.read<DebtFormCubit>();
    final form = t.debts.form;
    final lend = state.side == DebtSide.lent;
    final today = state.today;
    final first = '${CivilDate(today.year - 5, 1, 1)}';
    final last = '${CivilDate(today.year + 5, 12, 31)}';
    final currency = state.currency;
    final accountId = state.account?.id;
    final due = state.dueOn;
    final name = state.match?.name ?? state.name;
    final fresh = state.personId == null && state.name.trim().isNotEmpty;
    final twin = state.twin;
    return BirkaForm(
      title: !state.fixed
          ? t.debts.newDebt
          : lend
          ? form.moreTitle(name: name)
          : form.borrowMoreTitle(name: name),
      closeLabel: t.debts.close,
      onClose: component.onClose,
      submitLabel: form.save,
      onSubmit: () => unawaited(cubit.save()),
      submitting:
          state.status == DebtFormStatus.saving ||
          state.status == DebtFormStatus.saved,
      failure: state.status == DebtFormStatus.failed ? form.failed : null,
      children: [
        if (!state.fixed) ...[
          GlassSegmented<DebtSide>(
            segments: {
              DebtSide.lent: form.lend,
              DebtSide.borrowed: form.borrow,
            },
            selected: state.side,
            onChanged: cubit.sideChanged,
          ),
          div(classes: 'debt-form__who', [
            BirkaTextField(
              label: form.who,
              value: state.name,
              hint: form.nameHint,
              sentence: true,
              error: state.nameMissing ? form.nameMissing : null,
              onChanged: cubit.nameChanged,
            ),
            if (state.chips.isNotEmpty)
              div(classes: 'debt-form__people', [
                for (final person in state.chips)
                  BirkaChip(
                    key: ValueKey(person.id),
                    label: debtPersonLabel(person, state.people),
                    selected: state.personId == person.id,
                    onTap: () => cubit.personPicked(person),
                  ),
              ]),
          ]),
          BirkaFold(
            open: fresh,
            children: [
              if (twin != null)
                p(classes: 'text-caption debt-form__twin', [
                  .text(debtTwinLine(twin, picks: true)),
                ]),
              BirkaTextField(
                label: t.debts.person.about,
                value: state.about,
                hint: t.debts.person.aboutHint,
                sentence: true,
                onChanged: cubit.aboutChanged,
              ),
              BirkaTextField(
                label: t.debts.person.phone,
                value: state.phone ?? '',
                hint: t.debts.person.optional,
                inputMode: 'tel',
                onChanged: cubit.phoneChanged,
              ),
            ],
          ),
        ],
        BirkaFieldPair(
          children: [
            BirkaTextField(
              label: form.amount,
              value:
                  _amount ??
                  (state.amountMinor == 0 || currency == null
                      ? ''
                      : typedAmount(Money(state.amountMinor, currency))),
              hint: '0',
              inputMode: 'decimal',
              suffix: currency == null ? null : currencySign(currency),
              onChanged: (typed) {
                setState(() => _amount = typed);
                if (currency == null) return;
                final money = amountTyped(typed, currency);
                if (money != null) cubit.amountChanged(money.minorUnits);
              },
            ),
            if (accountId == null)
              GlassNotice(
                text: form.noAccount(
                  currency: state.match?.currency.code ?? '',
                ),
              )
            else
              BirkaSelectField<String>(
                label: lend ? form.fromAccount : form.toAccount,
                options: {
                  for (final row in state.offered)
                    row.account.id: row.account.name,
                },
                selected: accountId,
                onChanged: cubit.accountChanged,
              ),
          ],
        ),
        BirkaFieldPair(
          children: [
            BirkaDateField(
              label: form.when,
              text: state.day == today
                  ? form.today
                  : debtDay(state.day, today: today),
              value: '${state.day}',
              first: first,
              last: '$today',
              onChanged: (text) {
                if (_parse(text) case final day?) cubit.dayChanged(day);
              },
            ),
            // A cleared date takes the day away.
            BirkaDateField(
              label: form.dueBy,
              text: due == null ? form.noDue : debtDay(due, today: today),
              value: '${due ?? today.addDays(14)}',
              first: '$today',
              last: last,
              onChanged: (text) => cubit.dueChanged(_parse(text)),
            ),
          ],
        ),
        BirkaTextField(
          label: form.note,
          value: state.note,
          hint: form.noteHint,
          sentence: true,
          onChanged: cubit.noteChanged,
        ),
        p(classes: 'text-caption debt-form__note', [
          .text(lend ? form.lendCaption : form.borrowCaption),
        ]),
      ],
    );
  }

  /// A day from the calendar, or `null` for an empty or broken date.
  static CivilDate? _parse(String text) {
    final day = DateTime.tryParse(text);
    return day == null ? null : CivilDate.of(day);
  }
}
