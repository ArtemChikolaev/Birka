import 'dart:async';

import 'package:debts_common/debts_common.dart';
import 'package:debts_flutter/src/presentation/widgets/debt_choices.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

/// The form that changes a debt (ADR 0029): the name of the other person,
/// the day it should come back by and the reminder of that day.
///
/// It needs a [DebtTermsCubit] above it, and closes once saved.
class DebtTermsPage extends StatelessWidget {
  /// Creates the form.
  const DebtTermsPage({required this.onClose, super.key});

  /// Closes the form.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: BlocConsumer<DebtTermsCubit, DebtTermsState>(
            listenWhen: (before, now) =>
                before.status != now.status &&
                now.status == DebtTermsStatus.gone,
            listener: (context, state) => onClose(),
            builder: (context, state) => switch (state.status) {
              DebtTermsStatus.loading ||
              DebtTermsStatus.gone => const SizedBox.shrink(),
              _ => _Form(state: state, onClose: onClose),
            },
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state, required this.onClose});

  final DebtTermsState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DebtTermsCubit>();
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final form = t.debts.form;
    final due = state.dueOn;
    final name = state.name.trim();
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
                  form.editTitle,
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
                GlassListGroup(
                  children: [
                    GlassValueRow(
                      key: const ValueKey('name'),
                      label: form.name,
                      value: name.isEmpty ? form.nameHint : name,
                      quiet: name.isEmpty,
                      onTap: () => unawaited(_editName(context)),
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
                  ],
                ),
                if (state.nameMissing) ...[
                  const SizedBox(height: BirkaTokens.spaceXs),
                  Text(
                    form.nameMissing,
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
              if (state.status == DebtTermsStatus.failed) ...[
                Text(
                  form.failed,
                  textAlign: TextAlign.center,
                  style: styles.caption.copyWith(color: colors.negative),
                ),
                const SizedBox(height: BirkaTokens.spaceXs),
              ],
              BirkaButton(
                label: form.save,
                onPressed:
                    state.status == DebtTermsStatus.editing ||
                        state.status == DebtTermsStatus.failed
                    ? () => unawaited(cubit.save())
                    : null,
                done: state.status == DebtTermsStatus.saved,
                onDone: onClose,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editName(BuildContext context) async {
    final cubit = context.read<DebtTermsCubit>();
    final name = await showFieldSheet(
      context,
      label: t.debts.form.name,
      hint: t.debts.form.nameHint,
      done: t.debts.done,
      initial: state.name,
    );
    if (name != null) cubit.nameChanged(name);
  }

  Future<void> _pickDue(BuildContext context) async {
    final cubit = context.read<DebtTermsCubit>();
    final picked = await pickDebtDue(
      context,
      today: state.today,
      current: state.dueOn,
    );
    if (picked != null) cubit.dueChanged(picked.$1);
  }
}
