import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/schedules_common.dart';

/// The reminders of «Ещё» (ADR 0025): whether Birka reminds of the regular
/// payments with notifications of its own, at what time, and whether they
/// show the amounts.
///
/// It needs a [RemindersCubit] above it.
class RemindersSection extends StatefulWidget {
  /// Creates the section.
  const RemindersSection({super.key});

  @override
  State<RemindersSection> createState() => _RemindersSectionState();
}

class _RemindersSectionState extends State<RemindersSection> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // The person may come back from the settings of the phone with the
    // notifications turned on.
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(context.read<RemindersCubit>().accessChecked()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _pickTime(RemindersCubit cubit, int minutes) async {
    final picked = await showChoiceSheet<int>(
      context,
      title: t.schedules.remindTime,
      choices: reminderTimes,
      selected: minutes,
      labelOf: clockLabel,
    );
    if (picked case (final minutes,)) await cubit.timeChanged(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return BlocBuilder<RemindersCubit, RemindersState>(
      builder: (context, state) {
        final cubit = context.read<RemindersCubit>();
        final settings = state.settings ?? const ReminderSettings();
        final time = clockLabel(settings.minutes);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionLabel(t.schedules.remindTitle, color: colors.textMuted),
            const SizedBox(height: BirkaTokens.spaceXs),
            GlassListGroup(
              children: [
                GlassListRow(
                  key: const ValueKey('notify'),
                  title: t.schedules.remindNotify,
                  subtitle: state.denied
                      ? t.schedules.remindNotifyDenied
                      : settings.notify
                      ? t.schedules.remindNotifyOn(
                          n: state.reminding,
                          time: time,
                        )
                      : t.schedules.remindNotifyOff,
                  subtitleColor: state.denied
                      ? const Color(BirkaTokens.colorPaletteAmber)
                      : null,
                  trailing: Switch(
                    value: settings.notify,
                    onChanged: (on) => unawaited(
                      on ? turnRemindersOn(context, cubit) : cubit.disable(),
                    ),
                  ),
                ),
                if (settings.notify) ...[
                  GlassListRow(
                    key: const ValueKey('time'),
                    title: t.schedules.remindTime,
                    trailing: GlassListValue(time),
                    onTap: () => unawaited(_pickTime(cubit, settings.minutes)),
                  ),
                  GlassListRow(
                    key: const ValueKey('sums'),
                    title: t.schedules.remindSums,
                    subtitle: t.schedules.remindSumsNote,
                    trailing: Switch(
                      value: settings.sums,
                      onChanged: (sums) =>
                          unawaited(cubit.sumsChanged(sums: sums)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: BirkaTokens.spaceXs),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BirkaTokens.spaceXxs,
              ),
              child: FadingText(
                state.denied
                    ? t.schedules.remindNoteDenied
                    : settings.notify
                    ? t.schedules.remindNoteOn
                    : t.schedules.remindNoteOff,
                style: styles.caption.copyWith(color: colors.textMuted),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Turns the notifications of Birka on (ADR 0025): a sheet says first how
/// they come and asks, then the phone asks, and a toast says how it went. It
/// serves «Ещё» and the form of a payment whose reminders are off.
Future<void> turnRemindersOn(BuildContext context, RemindersCubit cubit) async {
  if (cubit.state.denied) return showRemindersDenied(context);
  final asked = await _ask(context, cubit);
  if (!asked || !context.mounted) return;
  final on = await cubit.enable();
  if (!context.mounted) return;
  if (!on) return showRemindersDenied(context);
  final count = cubit.state.reminding;
  showGlassToast(
    context,
    count > 0 ? t.schedules.remindOnText(n: count) : t.schedules.remindOnTitle,
  );
}

Future<bool> _ask(BuildContext context, RemindersCubit cubit) async {
  final colors = BirkaColors.of(context);
  final settings = cubit.state.settings ?? const ReminderSettings();
  final nearest = cubit.nearest;
  final today = CivilDate.of(DateTime.now());
  final allowed = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: colors.background,
    builder: (context) => ChoiceSheet(
      title: t.schedules.remindAskTitle,
      subtitle: t.schedules.remindAskText(time: clockLabel(settings.minutes)),
      children: [
        if (nearest != null) ...[
          GlassFileCard(
            mark: GlyphBadge(glyph: BirkaGlyph.bell, color: colors.accent),
            name: reminderNote(nearest, sums: settings.sums).title,
            line: t.schedules.remindAskExample(
              date: fullDate(nearest.day, today),
              time: clockLabel(nearest.minutes),
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceSm),
        ],
        GlassFileCard(
          mark: GlyphBadge(glyph: BirkaGlyph.phone, color: colors.textMuted),
          name: t.schedules.remindAskLocalTitle,
          line: t.schedules.remindAskLocalText,
        ),
        const SizedBox(height: BirkaTokens.spaceMd),
        BirkaButton(
          label: t.schedules.remindAllow,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        BirkaButton(
          label: t.schedules.remindNotNow,
          quiet: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
  );
  return allowed ?? false;
}

/// Says that the phone keeps the notifications of Birka off, and where in
/// its settings to turn them on.
Future<void> showRemindersDenied(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: BirkaColors.of(context).background,
      builder: (context) => ChoiceSheet(
        title: t.schedules.remindDeniedTitle,
        subtitle: t.schedules.remindDeniedText,
        children: [
          BirkaButton(
            label: t.schedules.remindUnderstood,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
