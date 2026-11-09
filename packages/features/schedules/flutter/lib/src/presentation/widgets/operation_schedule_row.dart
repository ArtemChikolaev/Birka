import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart';

/// The row of the regular payments on the card of an operation, as the board
/// «Операция → регулярный платёж» draws it (ADR 0023, point 22): «Сделать
/// регулярным» while the operation can become a payment, and the payment it
/// belongs to once it is one. When the operation becomes one, the row turns
/// into its payment once the form has gone off the card ([HeldOutOfSight]),
/// and a toast says so.
/// It needs an [OperationScheduleCubit] above it, and keeps the space under
/// it, so that it can close with it.
class OperationScheduleRow extends StatelessWidget {
  /// Creates the row.
  const OperationScheduleRow({
    required this.onMake,
    required this.onOpen,
    super.key,
  });

  /// Opens the form of a payment made from the operation.
  final VoidCallback onMake;

  /// Opens the payment of the given id.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OperationScheduleCubit, OperationScheduleState>(
      builder: (context, state) => HeldOutOfSight(
        value: state,
        onShown: (before, now) {
          if (now.schedule case final schedule? when before.offers) {
            showGlassToast(
              context,
              t.schedules.madeRegular(name: schedule.name),
            );
          }
        },
        builder: (context, state) {
          final schedule = state.schedule;
          final day = state.day;
          return AnimatedColumn(
            children: [
              if (schedule != null || day != null)
                Padding(
                  key: const ValueKey('schedule'),
                  padding: const EdgeInsets.only(bottom: BirkaTokens.spaceLg),
                  child: GlassListGroup(
                    children: [
                      AnimatedSwitcher(
                        duration: BirkaMotion.reduced(context)
                            ? Duration.zero
                            : BirkaMotion.base,
                        switchInCurve: BirkaMotion.fadeCurve,
                        switchOutCurve: BirkaMotion.fadeCurve,
                        child: schedule != null
                            ? _Row(
                                key: ValueKey(schedule.id),
                                title: t.schedules.regularPayment,
                                subtitle:
                                    '${schedule.name} · '
                                    '${everyLabel(schedule, state.today)}',
                                onTap: () => onOpen(schedule.id),
                              )
                            : _Row(
                                key: const ValueKey('offer'),
                                title: t.schedules.makeRegular,
                                subtitle: t.schedules.makeRegularLine(
                                  every: t.schedules.everyMonth(day: day!),
                                ),
                                onTap: onMake,
                              ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return GlassListRow(
      title: title,
      subtitle: subtitle,
      leading: GlyphBadge(glyph: BirkaGlyph.repeat, color: colors.accent),
      trailing: BirkaIcon(
        BirkaGlyph.chevron,
        size: 18,
        color: colors.textSubtle,
      ),
      onTap: onTap,
    );
  }
}
