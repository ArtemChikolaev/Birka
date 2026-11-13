import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/src/presentation/components/operation_day_group.dart';

/// The operations that wear a метка, day by day (ADR 0027): the latest
/// days, and every day after «Все N операций».
///
/// It needs a [TagOperationsCubit] above it.
class TagOperations extends StatelessComponent {
  /// Creates the list.
  const TagOperations({required this.hrefOf, super.key});

  /// Where the operation with this id opens.
  final String Function(String id) hrefOf;

  @override
  Component build(BuildContext context) {
    return BlocBuilder<TagOperationsCubit, TagOperationsState>(
      builder: (context, state) {
        if (!state.read) return const div([]);
        final cubit = context.read<TagOperationsCubit>();
        return div(classes: 'tag-operations', [
          for (final day in state.shown)
            OperationDayGroup(
              key: ValueKey(day.day),
              day: day,
              today: state.today,
              hrefOf: hrefOf,
            ),
          if (state.hasMore)
            div(classes: 'tag-operations__more', [
              BirkaChip(
                label: t.transactions.allOperations(
                  n: state.operations.length,
                ),
                selected: false,
                onTap: cubit.showAll,
              ),
            ]),
        ]);
      },
    );
  }

  /// The styles of the list.
  @css
  static List<StyleRule> get styles => [
    css('.tag-operations').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
      },
    ),
    css('.tag-operations__more').styles(
      raw: {'display': 'flex', 'justify-content': 'center'},
    ),
  ];
}
