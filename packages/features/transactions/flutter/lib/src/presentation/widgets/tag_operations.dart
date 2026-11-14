import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/src/presentation/widgets/delete_sheet.dart';
import 'package:transactions_flutter/src/presentation/widgets/operation_day_group.dart';

/// The operations that wear a метка, day by day (ADR 0027): the latest
/// days, and every day after «Все N операций».
///
/// It needs a [TagOperationsCubit] above it.
class TagOperations extends StatelessWidget {
  /// Creates the list.
  const TagOperations({
    required this.onOpen,
    required this.onRepeat,
    this.onOpenDebt,
    super.key,
  });

  /// Called with the id of the operation to open.
  final ValueChanged<String> onOpen;

  /// Called with the id of the operation to record once more.
  final ValueChanged<String> onRepeat;

  /// Called with the id of the debt that an operation moves, to open its
  /// card instead of the operation (ADR 0029). Without it the operation
  /// opens.
  final ValueChanged<String>? onOpenDebt;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TagOperationsCubit>();
    return BlocBuilder<TagOperationsCubit, TagOperationsState>(
      builder: (context, state) {
        if (!state.read) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The days that «all» brings open under the latest ones.
            AnimatedColumn(
              children: [
                for (final day in state.shown)
                  Padding(
                    key: ValueKey(day.day),
                    padding: const EdgeInsets.only(bottom: BirkaTokens.spaceLg),
                    child: OperationDayGroup(
                      day: day,
                      today: state.today,
                      onOpen: onOpen,
                      onOpenDebt: onOpenDebt,
                      onRepeat: onRepeat,
                      onDelete: (operation) =>
                          unawaited(_delete(context, cubit, operation)),
                    ),
                  ),
              ],
            ),
            if (state.deleteFailed)
              Text(
                t.transactions.failedToDelete,
                textAlign: TextAlign.center,
                style: BirkaTextStyles.of(
                  context,
                ).caption.copyWith(color: BirkaColors.of(context).negative),
              ),
            if (state.hasMore)
              Center(
                child: BirkaChip(
                  label: t.transactions.allOperations(
                    n: state.operations.length,
                  ),
                  selected: false,
                  onTap: cubit.showAll,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _delete(
    BuildContext context,
    TagOperationsCubit cubit,
    Operation operation,
  ) async {
    if (await confirmDelete(context, operation)) {
      await cubit.delete(operation.transaction.id);
    }
  }
}
