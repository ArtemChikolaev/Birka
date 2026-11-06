import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:inbox_flutter/src/presentation/inbox_bits.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// An operation without a category: the box that picks it, its name, its day
/// and account, its amount, and under them its hint with a «Да» and any
/// other category.
class InboxRow extends StatelessWidget {
  /// Creates the row of [item]; [onSay] tells the person what happened, and
  /// [onNewCategory] makes a category for it.
  const InboxRow({
    required this.item,
    required this.state,
    required this.thisYear,
    required this.onSay,
    this.onNewCategory,
    super.key,
  });

  /// The operation.
  final InboxItem item;

  /// The inbox.
  final InboxState state;

  /// The year of today, which dates of it leave out.
  final int thisYear;

  /// Shows a word on what was done, over the page.
  final ValueChanged<String> onSay;

  /// Makes a category with the person, for the sheet of categories.
  final CategoryMaker? onNewCategory;

  Future<void> _accept(InboxCubit cubit, Category category) async {
    await cubit.accept(item.id);
    if (!cubit.state.failed) onSay(t.inbox.accepted(category: category.name));
  }

  Future<void> _choose(BuildContext context, InboxCubit cubit) async {
    final kind = kindOf(item.transaction);
    final category = await chooseCategory(
      context,
      state,
      [kind],
      title: t.inbox.categoryFor(name: nameOf(item)),
      hinted: item.hint?.categoryId,
      onNew: onNewCategory,
    );
    // A new category can be of the other kind, which the operation cannot
    // take.
    if (category == null || category.kind != kind) return;
    await cubit.choose(item.id, category.id);
    if (!cubit.state.failed) {
      onSay(
        t.inbox.sorted(category: category.name, operations: operationsOf(1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final cubit = context.read<InboxCubit>();
    final transaction = item.transaction;
    final name = nameOf(item);
    final busy = state.busy.contains(item.id);
    final hint = item.hint;
    final hinted = hint == null
        ? null
        : state.categories.where((it) => it.id == hint.categoryId).firstOrNull;
    return AnimatedOpacity(
      opacity: busy ? 0.5 : 1,
      duration: const Duration(milliseconds: BirkaTokens.durationFastMs),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BirkaTokens.spaceXxs,
          BirkaTokens.spaceXs,
          BirkaTokens.spaceMd,
          BirkaTokens.spaceSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BirkaCheckbox(
                  checked: state.selected.contains(item.id),
                  label: t.inbox.pick(name: name),
                  onChanged: busy ? null : (_) => cubit.toggle(item.id),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: styles.bodyStrong.copyWith(color: colors.text),
                      ),
                      Text(
                        placeLabel(transaction, state, thisYear),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: styles.caption.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BirkaTokens.spaceSm),
                AmountText(
                  amountLabel(transaction),
                  tone: toneOf(transaction),
                  style: styles.bodyStrong,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: BirkaTokens.sizeTouchTarget,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: hint == null || hinted == null
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CategoryDot(hinted.color),
                                  const SizedBox(width: BirkaTokens.spaceXs),
                                  Flexible(
                                    child: Text(
                                      '${hinted.name} ?',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: styles.bodyStrong.copyWith(
                                        color: colors.text,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                hintLabel(hint, thisYear: thisYear),
                                style: styles.caption.copyWith(
                                  color: colors.textSubtle,
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (hinted != null) ...[
                    const SizedBox(width: BirkaTokens.spaceXs),
                    BirkaButton(
                      label: t.inbox.yes,
                      compact: true,
                      onPressed: busy
                          ? null
                          : () => unawaited(_accept(cubit, hinted)),
                    ),
                  ],
                  const SizedBox(width: BirkaTokens.spaceXs),
                  BirkaChip(
                    label: hinted == null ? t.inbox.category : t.inbox.other,
                    selected: false,
                    compact: true,
                    onTap: busy
                        ? null
                        : () => unawaited(_choose(context, cubit)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
