import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart';

/// The row of the regular payments on the card of an operation, as the board
/// «Операция → регулярный платёж» draws it (ADR 0023, point 22): «Сделать
/// регулярным» while the operation can become a payment, and the payment it
/// belongs to once it is one. When the operation becomes one, the row turns
/// into its payment and a toast says so once the form has gone off the card.
/// It needs an [OperationScheduleCubit] above it, and keeps the space under
/// it, so that it can close with it.
class OperationScheduleRow extends StatefulWidget {
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
  State<OperationScheduleRow> createState() => _OperationScheduleRowState();
}

class _OperationScheduleRowState extends State<OperationScheduleRow> {
  /// What a toast says once the card is on top again, if it waits.
  String? _waiting;
  Timer? _timer;

  /// Shows [text] in a toast once nothing covers the card: the form that
  /// made the payment goes down first, as on the board.
  void _say(String text) {
    if (ModalRoute.of(context)?.isCurrent ?? true) {
      return showGlassToast(context, text);
    }
    _waiting = text;
  }

  // The route tells its widgets when it comes on top again, as the page above
  // it starts to go, so the toast waits for that page to be gone.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.of(context)?.isCurrent ?? true;
    final text = _waiting;
    if (text == null || !current) return;
    _waiting = null;
    _timer?.cancel();
    _timer = Timer(BirkaSheetPage.closing, () {
      if (mounted) showGlassToast(context, text);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OperationScheduleCubit, OperationScheduleState>(
      listenWhen: (previous, current) =>
          previous.offers && current.schedule != null,
      listener: (context, state) =>
          _say(t.schedules.madeRegular(name: state.schedule!.name)),
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
                              onTap: () => widget.onOpen(schedule.id),
                            )
                          : _Row(
                              key: const ValueKey('offer'),
                              title: t.schedules.makeRegular,
                              subtitle: t.schedules.makeRegularLine(
                                every: t.schedules.everyMonth(day: day!),
                              ),
                              onTap: widget.onMake,
                            ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
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
