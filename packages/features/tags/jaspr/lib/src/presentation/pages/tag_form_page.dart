import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:tags_common/tags_common.dart';

/// The form of a метка (ADR 0027): a trip with its days and whether their
/// expenses get it by themselves, or a метка without days. Once saved, it
/// gives what the save wrote to [onDone], which closes it and says so.
///
/// It needs a [TagFormCubit] above it.
class TagFormPage extends StatelessComponent {
  /// Creates the form.
  const TagFormPage({required this.onClose, required this.onDone, super.key});

  /// Closes the form without a save.
  final VoidCallback onClose;

  /// Called once the метка is saved, with what the save wrote and whether
  /// the метка is new.
  final void Function(TagMarking saved, {required bool isNew}) onDone;

  @override
  Component build(BuildContext context) {
    return BlocConsumer<TagFormCubit, TagFormState>(
      listenWhen: (before, now) => before.status != now.status,
      listener: (_, state) {
        final saved = state.saved;
        if (state.status == TagFormStatus.saved && saved != null) {
          onDone(saved, isNew: state.isNew);
        }
      },
      builder: (context, state) => switch (state.status) {
        TagFormStatus.loading => const div([]),
        _ => _form(context, state),
      },
    );
  }

  Component _form(BuildContext context, TagFormState state) {
    final cubit = context.read<TagFormCubit>();
    final today = state.today;
    // The calendar keeps to the years around today, as on the phone.
    final first = '${CivilDate(today.year - 5, 1, 1)}';
    final last = '${CivilDate(today.year + 5, 12, 31)}';
    return BirkaForm(
      title: state.isNew ? t.tags.form.newTitle : state.name.trim(),
      closeLabel: t.tags.close,
      onClose: onClose,
      submitLabel: t.tags.form.save,
      onSubmit: () => unawaited(cubit.save()),
      submitting:
          state.status == TagFormStatus.saving ||
          state.status == TagFormStatus.saved,
      failure: state.status == TagFormStatus.failed ? t.tags.form.failed : null,
      children: [
        GlassSegmented<bool>(
          segments: {true: t.tags.form.trip, false: t.tags.form.plain},
          selected: state.trip,
          onChanged: (trip) => cubit.tripChanged(trip: trip),
        ),
        BirkaTextField(
          label: t.tags.form.name,
          value: state.name,
          hint: t.tags.form.namePlaceholder,
          sentence: true,
          error: state.nameMissing ? t.tags.form.nameMissing : null,
          onChanged: cubit.nameChanged,
        ),
        BirkaFold(
          open: state.trip,
          children: [
            BirkaFieldPair(
              children: [
                BirkaDateField(
                  label: t.tags.form.from,
                  text: _date(state.first, today),
                  value: '${state.first}',
                  first: first,
                  last: last,
                  onChanged: (text) {
                    if (_parse(text) case final day?) {
                      cubit.daysChanged(day, state.last);
                    }
                  },
                ),
                BirkaDateField(
                  label: t.tags.form.to,
                  text: _date(state.last, today),
                  value: '${state.last}',
                  first: first,
                  last: last,
                  onChanged: (text) {
                    if (_parse(text) case final day?) {
                      cubit.daysChanged(state.first, day);
                    }
                  },
                ),
              ],
            ),
            BirkaChoice(
              label: t.tags.form.marks,
              children: [
                BirkaChip(
                  label: t.tags.form.marksOn,
                  selected: state.marksDays,
                  onTap: () => cubit.marksChanged(marksDays: true),
                ),
                BirkaChip(
                  label: t.tags.form.marksOff,
                  selected: !state.marksDays,
                  onTap: () => cubit.marksChanged(marksDays: false),
                ),
              ],
            ),
            p(classes: 'text-caption tag-form__note', [
              .text(_marksNote(state)),
            ]),
          ],
        ),
        BirkaFold(
          open: !state.trip,
          children: [
            p(classes: 'text-caption tag-form__note', [
              .text(t.tags.form.plainNote),
            ]),
          ],
        ),
      ],
    );
  }

  static String _marksNote(TagFormState state) {
    if (!state.marksDays) return t.tags.form.manual;
    if (state.isNew && state.toMark > 0) {
      return t.tags.form.marksPast(n: state.toMark);
    }
    return t.tags.form.marksAhead;
  }

  static String _date(CivilDate day, CivilDate today) => dateLabel(
    year: day.year,
    month: day.month,
    day: day.day,
    thisYear: today.year,
  );

  /// A day from the calendar, or `null` for a date typed out of shape.
  static CivilDate? _parse(String text) {
    final day = DateTime.tryParse(text);
    return day == null ? null : CivilDate.of(day);
  }

  /// The styles of the form.
  @css
  static List<StyleRule> get styles => [
    css('.tag-form__note').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
  ];
}
