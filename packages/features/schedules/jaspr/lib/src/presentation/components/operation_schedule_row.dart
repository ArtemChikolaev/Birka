import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart';

/// The row of the regular payments on the card of an operation, as the board
/// «Операция на сайте · сделать регулярным» draws it (ADR 0023, point 22):
/// «Сделать регулярным» while the operation can become a payment, and the
/// payment it belongs to once it is one. Nothing while the operation is read
/// and for one that cannot repeat.
///
/// It needs an [OperationScheduleCubit] above it.
class OperationScheduleRow extends StatelessComponent {
  /// Creates the row.
  const OperationScheduleRow({
    required this.makeHref,
    required this.hrefOf,
    super.key,
  });

  /// Where the form of a payment made from the operation opens.
  final String makeHref;

  /// Where the payment of the given id opens.
  final String Function(String id) hrefOf;

  @override
  Component build(BuildContext context) {
    return BlocBuilder<OperationScheduleCubit, OperationScheduleState>(
      builder: (context, state) {
        final schedule = state.schedule;
        final day = state.day;
        if (schedule == null && day == null) return const div([]);
        return GlassListGroup(
          children: [
            GlassListRow(
              title: schedule == null
                  ? t.schedules.makeRegular
                  : t.schedules.regularPayment,
              subtitle: schedule == null
                  ? t.schedules.makeRegularLine(
                      every: t.schedules.everyMonth(day: day!),
                    )
                  : '${schedule.name} · ${everyLabel(schedule, state.today)}',
              leading: const GlyphBadge(
                glyph: BirkaGlyph.repeat,
                color: 'var(--color-accent)',
              ),
              href: schedule == null ? makeHref : hrefOf(schedule.id),
              chevron: true,
            ),
          ],
        );
      },
    );
  }
}
