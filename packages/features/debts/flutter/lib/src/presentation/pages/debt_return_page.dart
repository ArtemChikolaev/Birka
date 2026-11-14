import 'dart:async';

import 'package:debts_common/debts_common.dart';
import 'package:debts_flutter/src/presentation/widgets/debt_choices.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// The form of a return of a debt (ADR 0029): all that is left or a part,
/// the account in the currency of the debt and the day.
///
/// It needs a [DebtReturnCubit] above it. Once saved, it says what it wrote
/// in a toast and closes; a debt that is gone closes it at once.
class DebtReturnPage extends StatelessWidget {
  /// Creates the form.
  const DebtReturnPage({required this.onClose, super.key});

  /// Closes the form.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: BlocConsumer<DebtReturnCubit, DebtReturnState>(
            listenWhen: (before, now) =>
                before.status != now.status &&
                now.status == DebtReturnStatus.gone,
            listener: (context, state) => onClose(),
            builder: (context, state) => switch (state.debt) {
              null => const SizedBox.shrink(),
              final debt => _Form(state: state, debt: debt, onClose: onClose),
            },
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state, required this.debt, required this.onClose});

  final DebtReturnState state;
  final Debt debt;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DebtReturnCubit>();
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final back = t.debts.back;
    final form = t.debts.form;
    final lent = debt.side == DebtSide.lent;
    final part = Money(state.partMinor, debt.currency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BirkaTokens.spaceLg,
            BirkaTokens.spaceXs,
            BirkaTokens.spaceLg,
            BirkaTokens.spaceSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  debtReturnTitle(debt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.heading.copyWith(color: colors.text),
                ),
              ),
              GlassIconButton(
                glyph: BirkaGlyph.close,
                label: t.debts.close,
                glass: false,
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Expanded(
          child: ScrollEdgeFade(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: BirkaTokens.spaceLg,
                vertical: BirkaTokens.spaceXs,
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ChipSwitch<bool>(
                    options: {
                      true: HiddenAmounts.mask(context, debtReturnAll(debt)),
                      false: back.part,
                    },
                    selected: state.all,
                    onChanged: (all) {
                      cubit.allChanged(all: all);
                      // A part starts by asking how much.
                      if (!all && state.partMinor == 0) {
                        unawaited(_editPart(context, part));
                      }
                    },
                  ),
                ),
                const SizedBox(height: BirkaTokens.spaceLg),
                GlassListGroup(
                  children: [
                    if (!state.all)
                      GlassValueRow(
                        key: const ValueKey('part'),
                        label: form.amount,
                        value: HiddenAmounts.mask(context, formatMoney(part)),
                        quiet: state.partMinor == 0,
                        onTap: () => unawaited(_editPart(context, part)),
                      ),
                    GlassValueRow(
                      key: const ValueKey('account'),
                      label: lent ? form.toAccount : form.fromAccount,
                      value: state.account?.name ?? '—',
                      onTap: state.offered.isEmpty
                          ? null
                          : () => unawaited(_pickAccount(context, lent)),
                    ),
                    GlassValueRow(
                      key: const ValueKey('day'),
                      label: form.when,
                      value: debtDayValue(state.day, today: state.today),
                      onTap: () => unawaited(_pickDay(context)),
                    ),
                  ],
                ),
                if (state.tooMuch) ...[
                  const SizedBox(height: BirkaTokens.spaceXs),
                  Text(
                    back.tooMuch,
                    style: styles.caption.copyWith(color: colors.negative),
                  ),
                ],
                if (state.noAccount) ...[
                  const SizedBox(height: BirkaTokens.spaceXs),
                  Text(
                    form.noAccount(currency: debt.currency.code),
                    style: styles.caption.copyWith(color: colors.negative),
                  ),
                ],
                const SizedBox(height: BirkaTokens.spaceMd),
                FadingText(
                  HiddenAmounts.mask(
                    context,
                    debtReturnCaption(state, reminders: true),
                  ),
                  style: styles.caption.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BirkaTokens.spaceLg,
            BirkaTokens.spaceXs,
            BirkaTokens.spaceLg,
            BirkaTokens.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.status == DebtReturnStatus.failed) ...[
                Text(
                  form.failed,
                  textAlign: TextAlign.center,
                  style: styles.caption.copyWith(color: colors.negative),
                ),
                const SizedBox(height: BirkaTokens.spaceXs),
              ],
              BirkaButton(
                label: form.save,
                onPressed: state.canSave ? () => unawaited(cubit.save()) : null,
                done: state.status == DebtReturnStatus.saved,
                onDone: () => _done(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _done(BuildContext context) {
    final saved = state.saved;
    if (saved != null) showGlassToast(context, debtReturnedToast(saved));
    onClose();
  }

  Future<void> _editPart(BuildContext context, Money part) async {
    final cubit = context.read<DebtReturnCubit>();
    final minorUnits = await editDebtAmount(
      context,
      label: t.debts.form.amount,
      amount: part,
    );
    if (minorUnits != null) cubit.partChanged(minorUnits);
  }

  Future<void> _pickAccount(BuildContext context, bool lent) async {
    final cubit = context.read<DebtReturnCubit>();
    final id = await pickDebtAccount(
      context,
      title: lent ? t.debts.form.toAccount : t.debts.form.fromAccount,
      accounts: state.offered,
      selected: state.accountId,
    );
    if (id != null) cubit.accountChanged(id);
  }

  Future<void> _pickDay(BuildContext context) async {
    final cubit = context.read<DebtReturnCubit>();
    final day = await pickDebtDay(
      context,
      today: state.today,
      current: state.day,
    );
    if (day != null) cubit.dayChanged(day);
  }
}
