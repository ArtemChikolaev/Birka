import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_flutter/src/presentation/widgets/schedule_bits.dart';

/// The list of regular payments (ADR 0023): the ones that wait for the
/// person, the next 30 days and every payment.
///
/// It needs a [SchedulesCubit] above it.
class SchedulesPage extends StatelessWidget {
  /// Creates the page.
  const SchedulesPage({
    required this.onBack,
    required this.onAdd,
    required this.onOpen,
    super.key,
  });

  /// Called by the way back.
  final VoidCallback onBack;

  /// Opens the form of a new payment.
  final VoidCallback onAdd;

  /// Opens the form of a payment, by its id.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return CalendarCatchUp(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AmbientBackground(
          child: SafeArea(
            bottom: false,
            child: BlocBuilder<SchedulesCubit, SchedulesState>(
              builder: (context, state) => ListView(
                padding: const EdgeInsets.fromLTRB(
                  BirkaTokens.spaceLg,
                  BirkaTokens.spaceXs,
                  BirkaTokens.spaceLg,
                  BirkaTokens.spaceXxl,
                ),
                children: [
                  BackHeader(
                    label: t.schedules.title,
                    backLabel: t.schedules.back,
                    onBack: onBack,
                    trailing: GlassIconButton(
                      glyph: BirkaGlyph.plus,
                      label: t.schedules.add,
                      onPressed: onAdd,
                    ),
                  ),
                  const SizedBox(height: BirkaTokens.spaceLg),
                  ...switch (state) {
                    SchedulesLoading() => const <Widget>[],
                    SchedulesFailed() => [
                      BirkaButton(
                        label: t.app.retry,
                        onPressed: () =>
                            unawaited(context.read<SchedulesCubit>().retry()),
                      ),
                    ],
                    SchedulesLoaded(:final view) when view.schedules.isEmpty =>
                      [_Empty(onAdd: onAdd)],
                    SchedulesLoaded(:final view) => _content(context, view),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, SchedulesView view) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final plan = view.plan;
    const mask = HiddenAmounts.mask;
    return [
      // A payment that was posted or skipped closes, and the list moves up.
      AnimatedColumn(
        children: [
          for (final schedule in view.waiting)
            Padding(
              key: ValueKey(schedule.id),
              padding: const EdgeInsets.only(bottom: BirkaTokens.spaceLg),
              child: _Waiting(view: view, schedule: schedule),
            ),
        ],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: SectionLabel(t.schedules.ahead, color: colors.textMuted),
          ),
          if (plan != null)
            Text(
              mask(
                context,
                t.schedules.aheadTotal(
                  date: fullDate(plan.payday ?? plan.end, view.today),
                  amount: formatMoney(-plan.paid),
                ),
              ),
              style: styles.caption.copyWith(color: colors.textSubtle),
            ),
        ],
      ),
      const SizedBox(height: BirkaTokens.spaceXs),
      if (view.ahead.isNotEmpty)
        GlassListGroup(
          children: [
            for (final it in view.ahead)
              GlassListRow(
                key: ValueKey('${it.schedule.id} ${it.on}'),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DateColumn(it.on),
                    const SizedBox(width: BirkaTokens.spaceXs),
                    ScheduleDot(view, it.schedule),
                  ],
                ),
                title: it.schedule.name,
                subtitle: scheduleWhere(view, it.schedule),
                trailing: Text(
                  mask(context, scheduleAmount(it.schedule)),
                  style: styles.bodyStrong.copyWith(
                    color: scheduleInk(context, it.schedule),
                  ),
                ),
              ),
          ],
        ),
      if (plan != null) ...[
        const SizedBox(height: BirkaTokens.spaceXs),
        Text(
          mask(
            context,
            switch (plan.payday) {
              final payday? when plan.until == SpendUntil.payday =>
                t.schedules.leftAfterPayday(
                  date: fullDate(payday, view.today),
                  amount: formatMoney(plan.morning - plan.paid),
                ),
              _ => t.schedules.leftAfterMonth(
                amount: formatMoney(plan.morning - plan.paid),
              ),
            },
          ),
          style: styles.caption.copyWith(color: colors.textMuted),
        ),
      ],
      const SizedBox(height: BirkaTokens.spaceLg),
      SectionLabel(
        t.schedules.section(
          title: t.schedules.all,
          count: formatCount(view.schedules.length),
        ),
        color: colors.textMuted,
      ),
      const SizedBox(height: BirkaTokens.spaceXs),
      GlassListGroup(
        children: [
          for (final schedule in view.all)
            GlassListRow(
              key: ValueKey(schedule.id),
              leading: ScheduleDot(view, schedule),
              title: schedule.name,
              subtitle: scheduleLine(schedule, view.today),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mask(context, scheduleAmount(schedule)),
                    style: styles.bodyStrong.copyWith(
                      color: scheduleInk(context, schedule),
                    ),
                  ),
                  const SizedBox(width: BirkaTokens.spaceXs),
                  BirkaIcon(
                    BirkaGlyph.chevron,
                    size: 16,
                    color: colors.textMuted,
                  ),
                ],
              ),
              onTap: () => onOpen(schedule.id),
            ),
        ],
      ),
    ];
  }
}

/// A payment whose day came and that asks the person to post or skip it.
class _Waiting extends StatefulWidget {
  const _Waiting({required this.view, required this.schedule});

  final SchedulesView view;
  final Schedule schedule;

  @override
  State<_Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<_Waiting> {
  bool _busy = false;

  Future<void> _act({required bool post}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final cubit = context.read<SchedulesCubit>();
    final schedule = widget.schedule;
    final today = widget.view.today;
    // The card closes once the payment moves on, so the toast comes first.
    showGlassToast(
      context,
      post
          ? postedLabel(schedule, schedule.amount)
          : skippedLabel(schedule, today),
    );
    await (post ? cubit.post(schedule) : cubit.skip(schedule));
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final view = widget.view;
    final schedule = widget.schedule;
    const amber = Color(BirkaTokens.colorPaletteAmber);
    return TintedBox(
      color: amber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(t.schedules.waitingTitle, color: amber),
          const SizedBox(height: BirkaTokens.spaceSm),
          Row(
            children: [
              const ExcludeSemantics(
                child: GlyphBadge(glyph: BirkaGlyph.calendar, color: amber),
              ),
              const SizedBox(width: BirkaTokens.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.schedules.waitingDay(
                        name: schedule.name,
                        day: dayLabel(schedule.next, view.today),
                      ),
                      style: styles.bodyStrong.copyWith(color: colors.text),
                    ),
                    Text(
                      scheduleWhere(view, schedule),
                      maxLines: 2,
                      style: styles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BirkaTokens.spaceSm),
              Text(
                HiddenAmounts.mask(context, scheduleAmount(schedule)),
                style: styles.bodyStrong.copyWith(
                  color: scheduleInk(context, schedule),
                ),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          Row(
            children: [
              Expanded(
                child: BirkaButton(
                  label: t.schedules.post,
                  onPressed: _busy ? null : () => unawaited(_act(post: true)),
                ),
              ),
              const SizedBox(width: BirkaTokens.spaceSm),
              Expanded(
                child: BirkaButton(
                  label: t.schedules.skip,
                  quiet: true,
                  onPressed: _busy ? null : () => unawaited(_act(post: false)),
                ),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceSm),
          Text(
            t.schedules.waitingNote,
            style: styles.caption.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: BirkaTokens.spaceXxl),
      child: Column(
        children: [
          ExcludeSemantics(
            child: GlyphBadge(glyph: BirkaGlyph.repeat, color: colors.accent),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          Text(
            t.schedules.emptyTitle,
            textAlign: TextAlign.center,
            style: styles.heading.copyWith(color: colors.text),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          Text(
            t.schedules.emptyText,
            textAlign: TextAlign.center,
            style: styles.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
          SizedBox(
            width: double.infinity,
            child: BirkaButton(label: t.schedules.emptyAdd, onPressed: onAdd),
          ),
        ],
      ),
    );
  }
}
