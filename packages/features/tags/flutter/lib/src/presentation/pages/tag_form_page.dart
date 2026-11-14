import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:tags_common/tags_common.dart';

/// The form of a метка (ADR 0027): a trip with its days and whether their
/// expenses get it by themselves, or a метка without days.
///
/// It needs a [TagFormCubit] above it. Once saved, it says what the save
/// did in a toast, and gives what it wrote to [onClose].
class TagFormPage extends StatelessWidget {
  /// Creates the form.
  const TagFormPage({required this.onClose, super.key});

  /// Closes the form, with what the save wrote or `null`.
  final ValueChanged<TagMarking?> onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: BlocBuilder<TagFormCubit, TagFormState>(
            builder: (context, state) => switch (state.status) {
              TagFormStatus.loading => const SizedBox.shrink(),
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

  final TagFormState state;
  final ValueChanged<TagMarking?> onClose;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TagFormCubit>();
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
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
                  state.isNew ? t.tags.form.newTitle : state.name.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.heading.copyWith(color: colors.text),
                ),
              ),
              GlassIconButton(
                glyph: BirkaGlyph.close,
                label: t.tags.close,
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
                GlassSegmented<bool>(
                  segments: {
                    true: t.tags.form.trip,
                    false: t.tags.form.plain,
                  },
                  selected: state.trip,
                  onChanged: (trip) => cubit.tripChanged(trip: trip),
                ),
                const SizedBox(height: BirkaTokens.spaceLg),
                GlassListGroup(
                  children: [
                    GlassValueRow(
                      key: const ValueKey('name'),
                      label: t.tags.form.name,
                      value: name.isEmpty ? t.tags.form.namePlaceholder : name,
                      quiet: name.isEmpty,
                      onTap: () => unawaited(_editName(context)),
                    ),
                    if (state.trip)
                      GlassValueRow(
                        key: const ValueKey('dates'),
                        label: t.tags.form.dates,
                        value: daysLabel(
                          state.days,
                          thisYear: state.today.year,
                        ),
                        onTap: () => unawaited(_pickDays(context)),
                      ),
                  ],
                ),
                if (state.nameMissing) ...[
                  const SizedBox(height: BirkaTokens.spaceXs),
                  Text(
                    t.tags.form.nameMissing,
                    style: styles.caption.copyWith(color: colors.negative),
                  ),
                ],
                const SizedBox(height: BirkaTokens.spaceLg),
                AnimatedColumn(
                  children: [
                    if (state.trip)
                      GlassSurface(
                        key: const ValueKey('marks'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.tags.form.marks,
                              style: styles.caption.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                            const SizedBox(height: BirkaTokens.spaceXs),
                            ChipSwitch<bool>(
                              options: {
                                true: t.tags.form.marksOn,
                                false: t.tags.form.marksOff,
                              },
                              selected: state.marksDays,
                              onChanged: (marksDays) =>
                                  cubit.marksChanged(marksDays: marksDays),
                            ),
                            const SizedBox(height: BirkaTokens.spaceSm),
                            FadingText(
                              _marksNote(state),
                              style: styles.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        t.tags.form.plainNote,
                        key: const ValueKey('plain'),
                        style: styles.caption.copyWith(color: colors.textMuted),
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
              if (state.status == TagFormStatus.failed) ...[
                Text(
                  t.tags.form.failed,
                  textAlign: TextAlign.center,
                  style: styles.caption.copyWith(color: colors.negative),
                ),
                const SizedBox(height: BirkaTokens.spaceXs),
              ],
              // Once saved, the button turns into a check mark, and the
              // toast comes as the form goes down.
              BirkaButton(
                label: t.tags.form.save,
                onPressed:
                    state.status == TagFormStatus.editing ||
                        state.status == TagFormStatus.failed
                    ? () => unawaited(cubit.save())
                    : null,
                done: state.status == TagFormStatus.saved,
                onDone: () => _done(context),
              ),
              const SizedBox(height: BirkaTokens.spaceXs),
              Text(
                state.trip ? t.tags.form.footTrip : t.tags.form.footPlain,
                textAlign: TextAlign.center,
                style: styles.caption.copyWith(color: colors.textMuted),
              ),
            ],
          ),
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

  void _done(BuildContext context) {
    final cubit = context.read<TagFormCubit>();
    final saved = state.saved;
    if (saved != null) {
      final name = saved.tag.name;
      showGlassToast(
        context,
        saved.marked > 0
            ? t.tags.marked(n: saved.marked, name: name)
            : state.isNew
            ? saved.tag.isTrip
                  ? t.tags.addedTrip(name: name)
                  : t.tags.addedTag(name: name)
            : t.tags.saved(name: name),
        action: saved.marked > 0 && state.isNew
            ? (label: t.tags.undo, onPressed: () => unawaited(cubit.undo()))
            : null,
      );
    }
    onClose(saved);
  }

  Future<void> _editName(BuildContext context) async {
    final cubit = context.read<TagFormCubit>();
    final name = await showFieldSheet(
      context,
      label: t.tags.form.name,
      hint: t.tags.form.namePlaceholder,
      done: t.tags.form.done,
      initial: state.name,
    );
    if (name != null) cubit.nameChanged(name);
  }

  Future<void> _pickDays(BuildContext context) async {
    final cubit = context.read<TagFormCubit>();
    final today = state.today;
    DateTime of(CivilDate day) => DateTime(day.year, day.month, day.day);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: of(state.first),
        end: of(state.last),
      ),
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5, 12, 31),
    );
    if (picked != null) {
      cubit.daysChanged(CivilDate.of(picked.start), CivilDate.of(picked.end));
    }
  }
}
