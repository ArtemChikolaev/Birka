import 'dart:async';

import 'package:debts_common/debts_common.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// The form that changes a debt (ADR 0029): the name of the other person,
/// who they are and their number, which go to all their debts (ADR 0030),
/// and the day it should come back by. A reminder set on a phone stays as
/// it is. It calls [onDone] once saved.
///
/// It needs a [DebtTermsCubit] above it.
class DebtTermsPage extends StatelessComponent {
  /// Creates the form.
  const DebtTermsPage({required this.onClose, required this.onDone, super.key});

  /// Closes the form without a save, and when the debt is gone.
  final VoidCallback onClose;

  /// Called once the terms are saved.
  final VoidCallback onDone;

  @override
  Component build(BuildContext context) {
    return BlocConsumer<DebtTermsCubit, DebtTermsState>(
      listenWhen: (before, now) => before.status != now.status,
      listener: (_, state) {
        if (state.status == DebtTermsStatus.saved) onDone();
        if (state.status == DebtTermsStatus.gone) onClose();
      },
      builder: (context, state) => switch (state.status) {
        DebtTermsStatus.loading || DebtTermsStatus.gone => const div([]),
        _ => _form(context, state),
      },
    );
  }

  Component _form(BuildContext context, DebtTermsState state) {
    final cubit = context.read<DebtTermsCubit>();
    final form = t.debts.form;
    final today = state.today;
    final due = state.dueOn;
    final words = t.debts.person;
    return BirkaForm(
      title: form.editTitle,
      closeLabel: t.debts.close,
      onClose: onClose,
      submitLabel: form.save,
      onSubmit: () => unawaited(cubit.save()),
      submitting: state.status == DebtTermsStatus.saved,
      failure: state.status == DebtTermsStatus.failed ? form.failed : null,
      // The person is one for all their debts, and so is the save.
      note: words.sharedSite,
      children: [
        BirkaTextField(
          label: form.name,
          value: state.name,
          hint: form.nameHint,
          sentence: true,
          error: state.nameMissing ? form.nameMissing : null,
          onChanged: cubit.nameChanged,
        ),
        BirkaTextField(
          label: words.about,
          value: state.about,
          hint: words.aboutHint,
          sentence: true,
          onChanged: cubit.aboutChanged,
        ),
        BirkaTextField(
          label: words.phone,
          value: state.phone ?? '',
          hint: words.optional,
          inputMode: 'tel',
          onChanged: cubit.phoneChanged,
        ),
        // A cleared date takes the day away.
        BirkaDateField(
          label: form.dueBy,
          text: due == null ? form.noDue : debtDay(due, today: today),
          value: '${due ?? today.addDays(14)}',
          first: '${CivilDate(today.year - 5, 1, 1)}',
          last: '${CivilDate(today.year + 5, 12, 31)}',
          onChanged: (text) {
            final day = DateTime.tryParse(text);
            cubit.dueChanged(day == null ? null : CivilDate.of(day));
          },
        ),
      ],
    );
  }
}
