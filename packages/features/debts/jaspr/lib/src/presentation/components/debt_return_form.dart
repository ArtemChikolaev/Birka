import 'dart:async';

import 'package:debts_common/debts_common.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// The return of a debt in the fold under the actions of its card
/// (ADR 0029): all that is left or a part, the account in the currency of
/// the debt and the day. Once saved, it gives what it wrote to [onDone].
///
/// It needs a [DebtReturnCubit] above it.
class DebtReturnForm extends StatefulComponent {
  /// Creates the form.
  const DebtReturnForm({required this.onDone, super.key});

  /// Called once the return is saved.
  final ValueChanged<DebtReturned> onDone;

  @override
  State<DebtReturnForm> createState() => _DebtReturnFormState();

  /// The styles of the form.
  @css
  static List<StyleRule> get styles => [
    css('.debt-return').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
      },
    ),
    css('.debt-return__note').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
  ];
}

class _DebtReturnFormState extends State<DebtReturnForm> {
  /// What the person typed as the part, kept as typed.
  String? _part;

  @override
  Component build(BuildContext context) {
    return BlocConsumer<DebtReturnCubit, DebtReturnState>(
      listenWhen: (before, now) => before.status != now.status,
      listener: (_, state) {
        final saved = state.saved;
        if (state.status == DebtReturnStatus.saved && saved != null) {
          component.onDone(saved);
        }
      },
      builder: (context, state) => switch (state.debt) {
        null => const div([]),
        final debt => _form(context, state, debt),
      },
    );
  }

  Component _form(BuildContext context, DebtReturnState state, Debt debt) {
    final cubit = context.read<DebtReturnCubit>();
    final back = t.debts.back;
    final form = t.debts.form;
    final lent = debt.side == DebtSide.lent;
    final accountId = state.accountId;
    final today = state.today;
    return GlassSurface(
      child: div(classes: 'debt-return', [
        BirkaChoice(
          label: lent ? back.howMuchReturned : back.howMuchRepaid,
          children: [
            BirkaChip(
              label: debtReturnAll(debt),
              selected: state.all,
              onTap: () => cubit.allChanged(all: true),
            ),
            BirkaChip(
              label: back.part,
              selected: !state.all,
              onTap: () => cubit.allChanged(all: false),
            ),
          ],
        ),
        BirkaFold(
          open: !state.all,
          children: [
            BirkaTextField(
              label: form.amount,
              value:
                  _part ??
                  (state.partMinor == 0
                      ? ''
                      : typedAmount(Money(state.partMinor, debt.currency))),
              hint: '0',
              inputMode: 'decimal',
              suffix: currencySign(debt.currency),
              error: state.tooMuch ? back.tooMuch : null,
              onChanged: (typed) {
                setState(() => _part = typed);
                final money = amountTyped(typed, debt.currency);
                if (money != null) cubit.partChanged(money.minorUnits);
              },
            ),
          ],
        ),
        if (accountId == null)
          GlassNotice(text: form.noAccount(currency: debt.currency.code))
        else
          BirkaFieldPair(
            children: [
              BirkaSelectField<String>(
                label: lent ? form.toAccount : form.fromAccount,
                options: {
                  for (final row in state.offered)
                    row.account.id: row.account.name,
                },
                selected: accountId,
                onChanged: cubit.accountChanged,
              ),
              BirkaDateField(
                label: form.when,
                text: _dayText(state.day, today),
                value: '${state.day}',
                first: '${CivilDate(today.year - 5, 1, 1)}',
                last: '$today',
                onChanged: (text) {
                  if (_parse(text) case final day?) cubit.dayChanged(day);
                },
              ),
            ],
          ),
        p(classes: 'text-caption debt-return__note', [
          .text(debtReturnCaption(state, reminders: false)),
        ]),
        if (state.status == DebtReturnStatus.failed)
          GlassNotice(text: form.failed),
        BirkaButton(
          label: back.save,
          onPressed: state.canSave ? () => unawaited(cubit.save()) : null,
        ),
      ]),
    );
  }

  static String _dayText(CivilDate day, CivilDate today) =>
      day == today ? t.debts.form.today : debtDay(day, today: today);

  /// A day from the calendar, or `null` for a date typed out of shape.
  static CivilDate? _parse(String text) {
    final day = DateTime.tryParse(text);
    return day == null ? null : CivilDate.of(day);
  }
}
