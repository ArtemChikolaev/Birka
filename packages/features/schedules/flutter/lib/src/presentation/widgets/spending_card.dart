import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:schedules_flutter/src/presentation/widgets/schedule_bits.dart';

/// The card of the overview with the money of the day and the nearest
/// regular payments (ADR 0023): what today may still take, a bar of what it
/// took, and the three nearest payments. Without a salary to count until, it
/// asks for the payday; without accounts, it stays away.
///
/// It needs a [SchedulesCubit] above it.
class SpendingCard extends StatelessWidget {
  /// Creates the card.
  const SpendingCard({
    required this.onOpenPlan,
    required this.onOpenList,
    super.key,
  });

  /// Opens the money until the salary.
  final VoidCallback onOpenPlan;

  /// Opens the list of regular payments.
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    return CalendarCatchUp(
      child: BlocBuilder<SchedulesCubit, SchedulesState>(
        builder: (context, state) {
          final view = switch (state) {
            SchedulesLoaded(:final view) when view.base != null => view,
            _ => null,
          };
          final plan = view?.plan;
          // It comes and goes as the inbox strip does, and keeps the space
          // under it, so that it closes with it.
          return AnimatedColumn(
            children: [
              if (view != null)
                Padding(
                  key: const ValueKey('money'),
                  padding: const EdgeInsets.only(bottom: BirkaTokens.spaceLg),
                  child: AnimatedSize(
                    duration: BirkaMotion.reduced(context)
                        ? Duration.zero
                        : BirkaMotion.slow,
                    curve: BirkaMotion.standardCurve,
                    alignment: Alignment.topCenter,
                    child: plan == null
                        ? _NoPayday(onOpenPlan: onOpenPlan)
                        : _Plan(
                            view: view,
                            plan: plan,
                            onOpenPlan: onOpenPlan,
                            onOpenList: onOpenList,
                          ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Plan extends StatelessWidget {
  const _Plan({
    required this.view,
    required this.plan,
    required this.onOpenPlan,
    required this.onOpenList,
  });

  final SchedulesView view;
  final SpendingPlan plan;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final left = plan.leftToday;
    const mask = HiddenAmounts.mask;
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpenPlan,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FadingText(
                          (plan.over
                                  ? t.schedules.overToday
                                  : t.schedules.canSpend)
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: styles.label.copyWith(color: colors.textMuted),
                        ),
                      ),
                      BirkaIcon(
                        BirkaGlyph.chevron,
                        size: 16,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: BirkaTokens.spaceXs),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: BirkaTokens.spaceXs,
                    children: [
                      AmountText(
                        formatMoney(left),
                        value: left.minorUnits,
                        rise: AmountRise.good,
                        tone: plan.over
                            ? AmountTone.negative
                            : AmountTone.neutral,
                        style: styles.hero,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          mask(
                            context,
                            t.schedules.ofPerDay(
                              amount: formatMoney(plan.perDay),
                            ),
                          ),
                          style: styles.body.copyWith(color: colors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BirkaTokens.spaceSm),
                  _Bar(plan: plan),
                  const SizedBox(height: BirkaTokens.spaceSm),
                  FadingText(
                    mask(context, spentLabel(plan)),
                    style: styles.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          SizedBox(height: 1, child: ColoredBox(color: colors.hairline)),
          const SizedBox(height: BirkaTokens.spaceSm),
          SectionLabel(t.schedules.upcoming, color: colors.textMuted),
          AnimatedColumn(
            children: [
              for (final it in view.upcoming.take(3))
                _Upcoming(
                  key: ValueKey('${it.schedule.id} ${it.on}'),
                  view: view,
                  occurrence: it,
                ),
            ],
          ),
          AccentLink(
            label: view.schedules.isEmpty
                ? t.schedules.emptyAdd
                : t.schedules.section(
                    title: t.schedules.all,
                    count: formatCount(view.schedules.length),
                  ),
            onTap: onOpenList,
            expand: true,
          ),
        ],
      ),
    );
  }
}

/// How much of its share today took: it grows as the day spends, and turns
/// to the color of a loss once today took more.
class _Bar extends StatelessWidget {
  const _Bar({required this.plan});

  final SpendingPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final reduced = BirkaMotion.reduced(context);
    final perDay = plan.perDay.minorUnits;
    final spent = plan.spentToday.minorUnits;
    final share = perDay > 0
        ? (spent / perDay).clamp(0.0, 1.0)
        : (spent > 0 ? 1.0 : 0.0);
    final color = plan.over ? colors.negative : colors.accent;
    return Semantics(
      label: t.schedules.canSpend,
      value: '${(share * 100).round()}%',
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        child: SizedBox(
          height: 8,
          child: ColoredBox(
            color: colors.surfaceRaised,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: share),
              duration: reduced ? Duration.zero : BirkaMotion.roll,
              curve: BirkaMotion.standardCurve,
              builder: (context, value, _) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: value,
                  heightFactor: 1,
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: color),
                    duration: BirkaMotion.slow,
                    curve: BirkaMotion.fadeCurve,
                    builder: (context, ink, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: ink,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Upcoming extends StatelessWidget {
  const _Upcoming({required this.view, required this.occurrence, super.key});

  final SchedulesView view;
  final Occurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final schedule = occurrence.schedule;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              occurrence.on == view.today
                  ? t.schedules.today
                  : shortDate(occurrence.on),
              style: styles.caption.copyWith(color: colors.textMuted),
            ),
          ),
          ScheduleDot(view, schedule),
          const SizedBox(width: BirkaTokens.spaceSm),
          Expanded(
            child: Text(
              occurrenceName(schedule, occurrence.on),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: styles.bodyStrong.copyWith(color: colors.text),
            ),
          ),
          Text(
            HiddenAmounts.mask(
              context,
              occurrenceAmount(schedule, occurrence.on),
            ),
            style: styles.bodyStrong.copyWith(
              color: scheduleInk(context, schedule),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPayday extends StatelessWidget {
  const _NoPayday({required this.onOpenPlan});

  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(t.schedules.noPaydayLabel, color: colors.textMuted),
          const SizedBox(height: BirkaTokens.spaceXs),
          Text(
            t.schedules.noPaydayTitle,
            style: styles.heading.copyWith(color: colors.text),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          Text(
            t.schedules.noPaydayText,
            style: styles.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          BirkaButton(label: t.schedules.noPaydayAction, onPressed: onOpenPlan),
        ],
      ),
    );
  }
}
