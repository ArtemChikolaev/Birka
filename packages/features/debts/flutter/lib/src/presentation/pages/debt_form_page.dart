import 'dart:async';

import 'package:debts_common/debts_common.dart';
import 'package:debts_flutter/src/presentation/widgets/debt_choices.dart';
import 'package:debts_flutter/src/presentation/widgets/person_sheet.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// The form of a new debt, or of more money on one (ADR 0029): whether the
/// person lends or borrows, who, how much, from or to which account, when,
/// by what day, a note and the reminder of that day. Someone new comes from
/// a sheet of their own, which can take them from the contacts of [phone]
/// (ADR 0030).
///
/// It needs a [DebtFormCubit] above it. Once saved, it says what it wrote in
/// a toast, and gives the id of the debt to [onClose].
class DebtFormPage extends StatelessWidget {
  /// Creates the form.
  const DebtFormPage({required this.onClose, this.phone, super.key});

  /// Closes the form, with the id of the debt that the save wrote, or
  /// `null`.
  final ValueChanged<String?> onClose;

  /// The contacts of the phone, or `null` where there are none.
  final PeoplePhone? phone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: BlocBuilder<DebtFormCubit, DebtFormState>(
            builder: (context, state) => switch (state.status) {
              DebtFormStatus.loading => const SizedBox.shrink(),
              _ => _Form(state: state, onClose: onClose, phone: phone),
            },
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.state,
    required this.onClose,
    required this.phone,
  });

  final DebtFormState state;
  final ValueChanged<String?> onClose;
  final PeoplePhone? phone;

  String get _title {
    if (!state.fixed) return t.debts.newDebt;
    final name = state.match?.name ?? state.name;
    return state.side == DebtSide.lent
        ? t.debts.form.moreTitle(name: name)
        : t.debts.form.borrowMoreTitle(name: name);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DebtFormCubit>();
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final form = t.debts.form;
    final lend = state.side == DebtSide.lent;
    final amount = state.amount;
    final account = state.account;
    final due = state.dueOn;
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
                  _title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.heading.copyWith(color: colors.text),
                ),
              ),
              GlassIconButton(
                glyph: BirkaGlyph.close,
                label: t.debts.close,
                glass: false,
                onPressed: () => onClose(null),
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
                if (!state.fixed) ...[
                  GlassSegmented<DebtSide>(
                    segments: {
                      DebtSide.lent: form.lend,
                      DebtSide.borrowed: form.borrow,
                    },
                    selected: state.side,
                    onChanged: cubit.sideChanged,
                  ),
                  const SizedBox(height: BirkaTokens.spaceLg),
                  SectionLabel(form.who),
                  const SizedBox(height: BirkaTokens.spaceXs),
                  _People(state: state, phone: phone),
                  if (state.nameMissing) ...[
                    const SizedBox(height: BirkaTokens.spaceXs),
                    Text(
                      form.nameMissing,
                      style: styles.caption.copyWith(color: colors.negative),
                    ),
                  ],
                  const SizedBox(height: BirkaTokens.spaceLg),
                ],
                GlassListGroup(
                  children: [
                    GlassValueRow(
                      key: const ValueKey('amount'),
                      label: form.amount,
                      value: amount == null
                          ? '—'
                          : HiddenAmounts.mask(context, formatMoney(amount)),
                      quiet: state.amountMinor == 0,
                      onTap: amount == null
                          ? null
                          : () => unawaited(_editAmount(context, amount)),
                    ),
                    GlassValueRow(
                      key: const ValueKey('account'),
                      label: lend ? form.fromAccount : form.toAccount,
                      value: account?.name ?? '—',
                      onTap: state.offered.isEmpty
                          ? null
                          : () => unawaited(_pickAccount(context)),
                    ),
                    GlassValueRow(
                      key: const ValueKey('day'),
                      label: form.when,
                      value: debtDayValue(state.day, today: state.today),
                      onTap: () => unawaited(_pickDay(context)),
                    ),
                    GlassValueRow(
                      key: const ValueKey('due'),
                      label: form.dueBy,
                      value: due == null
                          ? form.noDue
                          : debtDay(due, today: state.today),
                      quiet: due == null,
                      onTap: () => unawaited(_pickDue(context)),
                    ),
                    GlassValueRow(
                      key: const ValueKey('note'),
                      label: form.note,
                      value: state.note.trim().isEmpty
                          ? form.noteHint
                          : state.note.trim(),
                      quiet: state.note.trim().isEmpty,
                      onTap: () => unawaited(_editNote(context)),
                    ),
                  ],
                ),
                if (state.noAccount) ...[
                  const SizedBox(height: BirkaTokens.spaceXs),
                  Text(
                    form.noAccount(currency: state.match!.currency.code),
                    style: styles.caption.copyWith(color: colors.negative),
                  ),
                ],
                AnimatedColumn(
                  children: [
                    if (due != null)
                      Padding(
                        key: const ValueKey('remind'),
                        padding: const EdgeInsets.only(
                          top: BirkaTokens.spaceSm,
                        ),
                        child: GlassListGroup(
                          children: [
                            GlassListRow(
                              title: form.remind,
                              trailing: Switch(
                                value: state.reminds,
                                onChanged: (on) =>
                                    cubit.remindsChanged(reminds: on),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: BirkaTokens.spaceMd),
                FadingText(
                  lend ? form.lendCaption : form.borrowCaption,
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
              if (state.status == DebtFormStatus.failed) ...[
                Text(
                  form.failed,
                  textAlign: TextAlign.center,
                  style: styles.caption.copyWith(color: colors.negative),
                ),
                const SizedBox(height: BirkaTokens.spaceXs),
              ],
              // Once saved, the button turns into a check mark, and the
              // toast comes as the form goes down.
              BirkaButton(
                label: form.save,
                onPressed: state.canSave || state.name.trim().isEmpty
                    ? () => unawaited(cubit.save())
                    : null,
                done: state.status == DebtFormStatus.saved,
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
    if (saved != null) showGlassToast(context, debtSavedToast(saved));
    onClose(saved?.debtId);
  }

  Future<void> _editAmount(BuildContext context, Money amount) async {
    final cubit = context.read<DebtFormCubit>();
    final minorUnits = await editDebtAmount(
      context,
      label: t.debts.form.amount,
      amount: amount,
    );
    if (minorUnits != null) cubit.amountChanged(minorUnits);
  }

  Future<void> _pickAccount(BuildContext context) async {
    final cubit = context.read<DebtFormCubit>();
    final id = await pickDebtAccount(
      context,
      title: state.side == DebtSide.lent
          ? t.debts.form.fromAccount
          : t.debts.form.toAccount,
      accounts: state.offered,
      selected: state.accountId,
    );
    if (id != null) cubit.accountChanged(id);
  }

  Future<void> _pickDay(BuildContext context) async {
    final cubit = context.read<DebtFormCubit>();
    final day = await pickDebtDay(
      context,
      today: state.today,
      current: state.day,
    );
    if (day != null) cubit.dayChanged(day);
  }

  Future<void> _pickDue(BuildContext context) async {
    final cubit = context.read<DebtFormCubit>();
    final picked = await pickDebtDue(
      context,
      today: state.today,
      current: state.dueOn,
    );
    if (picked != null) cubit.dueChanged(picked.$1);
  }

  Future<void> _editNote(BuildContext context) async {
    final cubit = context.read<DebtFormCubit>();
    final note = await showFieldSheet(
      context,
      label: t.debts.form.note,
      done: t.debts.done,
      initial: state.note,
    );
    if (note != null) cubit.noteChanged(note);
  }
}

/// The people of the debts as chips, and one more for someone new, who comes
/// from a sheet of their own (ADR 0030). A chip of a namesake says who they
/// are.
class _People extends StatelessWidget {
  const _People({required this.state, required this.phone});

  final DebtFormState state;
  final PeoplePhone? phone;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DebtFormCubit>();
    final typed = state.name.trim();
    final fresh = typed.isNotEmpty && state.personId == null
        ? Person(id: '', name: typed, about: state.about)
        : null;
    // Someone new of a name that is there makes both chips say who they are.
    final everyone = fresh == null ? state.people : [...state.people, fresh];
    return Wrap(
      spacing: BirkaTokens.spaceXs,
      runSpacing: BirkaTokens.spaceXs,
      children: [
        for (final person in state.chips)
          BirkaChip(
            key: ValueKey('person-${person.id}'),
            label: debtPersonLabel(person, everyone),
            selected: state.personId == person.id,
            onTap: () => cubit.personPicked(person),
          ),
        if (fresh != null)
          BirkaChip(
            key: const ValueKey('typed'),
            label: debtPersonLabel(fresh, everyone),
            selected: true,
            onTap: () => unawaited(_person(context)),
          ),
        BirkaChip(
          key: const ValueKey('other'),
          label: t.debts.form.other,
          glyph: BirkaGlyph.plus,
          dashed: true,
          selected: false,
          onTap: () => unawaited(_person(context)),
        ),
      ],
    );
  }

  Future<void> _person(BuildContext context) async {
    final cubit = context.read<DebtFormCubit>();
    final typed = state.name.trim();
    final person = await showPersonSheet(
      context,
      people: state.people,
      phone: phone,
      initial: typed.isNotEmpty && state.personId == null
          ? (name: typed, about: state.about, phone: state.phone)
          : null,
    );
    if (person == null || person.name.isEmpty) return;
    cubit
      ..nameChanged(person.name)
      ..aboutChanged(person.about)
      ..phoneChanged(person.phone);
  }
}
