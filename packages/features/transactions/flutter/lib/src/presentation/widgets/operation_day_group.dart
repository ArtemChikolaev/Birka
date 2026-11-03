import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/src/presentation/widgets/operation_row.dart';

/// The days of operations, the latest first, as a sliver: a day that comes
/// opens and a day that goes closes, as the rows in a day do.
class SliverOperationDays extends StatelessWidget {
  /// Creates the list of [days]. With [accountId] the amounts are what the
  /// operations did to that account.
  const SliverOperationDays({
    required this.days,
    required this.today,
    required this.onOpen,
    required this.onRepeat,
    required this.onDelete,
    this.accountId,
    super.key,
  });

  /// The days.
  final List<OperationDay> days;

  /// The day of today, which names the days.
  final CivilDate today;

  /// Called with the id of the operation to open.
  final ValueChanged<String> onOpen;

  /// Called with the id of the operation to record once more.
  final ValueChanged<String> onRepeat;

  /// Called with the operation to delete.
  final ValueChanged<Operation> onDelete;

  /// The account that the amounts are about.
  final String? accountId;

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedColumn(
      children: [
        for (final day in days)
          // The room under a day comes and goes with it.
          Padding(
            key: ValueKey(day.day),
            padding: const EdgeInsets.only(bottom: BirkaTokens.spaceLg),
            child: OperationDayGroup(
              day: day,
              today: today,
              accountId: accountId,
              onOpen: onOpen,
              onRepeat: onRepeat,
              onDelete: onDelete,
            ),
          ),
      ],
    );
  }
}

/// The operations of one day under a heading with what the day comes to.
class OperationDayGroup extends StatelessWidget {
  /// Creates a group of [day]. With [accountId] the amounts are what the
  /// operations did to that account.
  const OperationDayGroup({
    required this.day,
    required this.today,
    required this.onOpen,
    required this.onRepeat,
    required this.onDelete,
    this.accountId,
    super.key,
  });

  /// The day.
  final OperationDay day;

  /// The day of today, which names the day.
  final CivilDate today;

  /// Called with the id of the operation to open.
  final ValueChanged<String> onOpen;

  /// Called with the id of the operation to record once more.
  final ValueChanged<String> onRepeat;

  /// Called with the operation to delete.
  final ValueChanged<Operation> onDelete;

  /// The account that the amounts are about.
  final String? accountId;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final accountId = this.accountId;
    final total = accountId == null ? day.total : day.totalOn(accountId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BirkaTokens.spaceXs,
          ),
          child: Row(
            children: [
              SectionLabel(
                dayHeading(day.day, today: today),
                color: colors.textSecondary,
              ),
              const SizedBox(width: BirkaTokens.spaceSm),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AmountText(
                    amountsLabel(total),
                    value: total.length == 1 ? total.single.minorUnits : null,
                    rise: AmountRise.good,
                    tone: AmountTone.muted,
                    style: BirkaTextStyles.of(context).caption,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        GlassListGroup(
          children: [
            for (final operation in day.operations)
              OperationRow(
                key: ValueKey(operation.id),
                operation: operation,
                accountId: accountId,
                onOpen: () => onOpen(operation.id),
                onRepeat: () => onRepeat(operation.id),
                onDelete: () => onDelete(operation),
              ),
          ],
        ),
      ],
    );
  }
}
