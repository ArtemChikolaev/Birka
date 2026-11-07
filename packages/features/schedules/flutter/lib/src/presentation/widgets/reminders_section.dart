import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/schedules_common.dart';

/// The reminders of «Ещё» (ADR 0025): whether Birka reminds of the regular
/// payments with notifications of its own and with the events of a calendar
/// of its own, at what time, and whether they show the amounts.
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
                  subtitleColor: state.denied ? _amber : null,
                  trailing: Switch(
                    value: settings.notify,
                    onChanged: (on) => unawaited(
                      on ? turnRemindersOn(context, cubit) : cubit.disable(),
                    ),
                  ),
                ),
                GlassListRow(
                  key: const ValueKey('calendar'),
                  title: t.schedules.remindCalendar,
                  subtitle: state.calendarDenied
                      ? t.schedules.remindCalendarDenied
                      : settings.calendar
                      ? t.schedules.remindCalendarOn(n: state.events)
                      : t.schedules.remindCalendarOff,
                  subtitleColor: state.calendarDenied ? _amber : null,
                  trailing: Switch(
                    value: settings.calendar,
                    onChanged: (on) => unawaited(
                      on
                          ? turnCalendarOn(context, cubit)
                          : _turnCalendarOff(context, cubit),
                    ),
                  ),
                ),
                if (settings.any) ...[
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
                _note(state, settings),
                style: styles.caption.copyWith(color: colors.textMuted),
              ),
            ),
          ],
        );
      },
    );
  }
}

const _amber = Color(BirkaTokens.colorPaletteAmber);

/// What the caption under the group says: why a way stays off, or what the
/// ways that are on mean.
String _note(RemindersState state, ReminderSettings settings) {
  if (state.denied) return t.schedules.remindNoteDenied;
  if (state.calendarDenied) return t.schedules.remindNoteCalendarDenied;
  return switch ((settings.notify, settings.calendar)) {
    (true, true) => t.schedules.remindNoteBoth,
    (true, false) => t.schedules.remindNoteOn,
    (false, true) => t.schedules.remindNoteCalendar,
    (false, false) => t.schedules.remindNoteOff,
  };
}

/// Turns the notifications of Birka on (ADR 0025): a sheet says first how
/// they come and asks, then the phone asks, and a toast says how it went. It
/// serves «Ещё» and the form of a payment whose reminders are off.
Future<void> turnRemindersOn(BuildContext context, RemindersCubit cubit) async {
  if (cubit.state.denied) return _showNotificationsDenied(context, cubit);
  final asked = await _ask(context, cubit);
  if (!asked || !context.mounted) return;
  final on = await cubit.enable();
  if (!context.mounted) return;
  if (!on) return _showNotificationsDenied(context, cubit);
  final count = cubit.state.reminding;
  showGlassToast(
    context,
    count > 0 ? t.schedules.remindOnText(n: count) : t.schedules.remindOnTitle,
  );
}

/// Turns the events of the calendar «Birka» on (ADR 0025): a sheet says what
/// Birka writes there and why the phone asks for full access, then the phone
/// asks, and a toast says how it went.
Future<void> turnCalendarOn(BuildContext context, RemindersCubit cubit) async {
  if (cubit.state.calendarDenied) return _showCalendarDenied(context, cubit);
  final asked = await _askCalendar(context, cubit);
  if (!asked || !context.mounted) return;
  final on = await cubit.enableCalendar();
  if (!context.mounted) return;
  if (!on) return _showCalendarDenied(context, cubit);
  showGlassToast(context, t.schedules.remindCalendarOnToast);
}

/// Asks before the calendar «Birka» goes with its events, then removes it.
Future<void> _turnCalendarOff(
  BuildContext context,
  RemindersCubit cubit,
) async {
  final sure = await _sheet<bool>(
    context,
    (context) => ChoiceSheet(
      title: t.schedules.remindCalendarRemoveTitle,
      subtitle: t.schedules.remindCalendarRemoveText(n: cubit.state.events),
      children: [
        BirkaButton(
          label: t.schedules.remindCalendarRemove,
          danger: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        BirkaButton(
          label: t.schedules.remindCancel,
          quiet: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
  );
  if (!(sure ?? false) || !context.mounted) return;
  final removed = await cubit.disableCalendar();
  if (!context.mounted) return;
  if (!removed) return _showCalendarDenied(context, cubit);
  showGlassToast(context, t.schedules.remindCalendarOffToast);
}

Future<bool> _ask(BuildContext context, RemindersCubit cubit) async {
  final colors = BirkaColors.of(context);
  final settings = cubit.state.settings ?? const ReminderSettings();
  final nearest = cubit.nearest;
  final today = CivilDate.of(DateTime.now());
  final allowed = await _sheet<bool>(
    context,
    (context) => ChoiceSheet(
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

Future<bool> _askCalendar(BuildContext context, RemindersCubit cubit) async {
  final colors = BirkaColors.of(context);
  final settings = cubit.state.settings ?? const ReminderSettings();
  final allowed = await _sheet<bool>(
    context,
    (context) => ChoiceSheet(
      title: t.schedules.remindCalendar,
      subtitle: t.schedules.remindCalendarAskText,
      children: [
        GlassFileCard(
          mark: const GlyphBadge(
            glyph: BirkaGlyph.calendar,
            color: Color(BirkaTokens.colorPaletteSky),
          ),
          name: t.schedules.remindCalendarAskOwnTitle,
          line: t.schedules.remindCalendarAskOwn(
            n: cubit.state.reminding,
            time: clockLabel(settings.minutes),
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceSm),
        GlassFileCard(
          mark: const GlyphBadge(glyph: BirkaGlyph.cloud, color: _amber),
          name: t.schedules.remindCalendarAskSyncTitle,
          line: t.schedules.remindCalendarAskSyncText,
        ),
        const SizedBox(height: BirkaTokens.spaceSm),
        GlassFileCard(
          mark: GlyphBadge(glyph: BirkaGlyph.hidden, color: colors.textMuted),
          name: t.schedules.remindCalendarAskOthersTitle,
          line: t.schedules.remindCalendarAskOthersText,
        ),
        const SizedBox(height: BirkaTokens.spaceMd),
        BirkaButton(
          label: t.schedules.remindCalendarAllow,
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
Future<void> _showNotificationsDenied(
  BuildContext context,
  RemindersCubit cubit,
) => _showDenied(
  context,
  cubit,
  title: t.schedules.remindDeniedTitle,
  text: t.schedules.remindDeniedText,
);

/// Says that the phone keeps the calendar from Birka, and where in its
/// settings to give the full access.
Future<void> _showCalendarDenied(BuildContext context, RemindersCubit cubit) =>
    _showDenied(
      context,
      cubit,
      title: t.schedules.remindCalendarDeniedTitle,
      text: t.schedules.remindCalendarDeniedText,
    );

Future<void> _showDenied(
  BuildContext context,
  RemindersCubit cubit, {
  required String title,
  required String text,
}) => _sheet<void>(
  context,
  (context) => ChoiceSheet(
    title: title,
    subtitle: text,
    children: [
      BirkaButton(
        label: t.schedules.remindOpenSettings,
        onPressed: () {
          Navigator.of(context).pop();
          unawaited(cubit.openSettings());
        },
      ),
      const SizedBox(height: BirkaTokens.spaceXs),
      BirkaButton(
        label: t.schedules.remindCancel,
        quiet: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  ),
);

/// Shows a sheet of the reminders over the whole app, the bar included.
Future<T?> _sheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: BirkaColors.of(context).background,
      builder: builder,
    );
