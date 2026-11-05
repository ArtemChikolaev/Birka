import 'dart:async';
import 'dart:math' as math;

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:inbox_flutter/src/presentation/inbox_bits.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// A transfer between one's own accounts to link: the money that left one
/// account, the money that reached the other, the rate against that of the
/// bank, and the two answers.
class PairCard extends StatelessWidget {
  /// Creates the card of [pair]; [onSay] tells the person what happened.
  const PairCard({
    required this.pair,
    required this.state,
    required this.thisYear,
    required this.onSay,
    super.key,
  });

  /// The pair.
  final TransferPair pair;

  /// The inbox.
  final InboxState state;

  /// The year of today, which dates of it leave out.
  final int thisYear;

  /// Shows a word on what was done, over the page.
  final ValueChanged<String> onSay;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final cubit = context.read<InboxCubit>();
    final busy = state.busy.contains(pair.key);
    final rate = rateLabel(pair, state.rates);
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GlyphBadge(glyph: BirkaGlyph.transfer, color: colors.accent),
              const SizedBox(width: BirkaTokens.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.inbox.pairTitle,
                      style: styles.bodyStrong.copyWith(color: colors.text),
                    ),
                    Text(
                      t.inbox.pairText,
                      style: styles.caption.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          _Side(transaction: pair.out, state: state, thisYear: thisYear),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: BirkaTokens.spaceXs,
              ),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Transform.rotate(
                  angle: math.pi / 2,
                  child: BirkaIcon(
                    BirkaGlyph.chevron,
                    size: 16,
                    color: colors.accent,
                  ),
                ),
              ),
            ),
          ),
          _Side(transaction: pair.into, state: state, thisYear: thisYear),
          if (rate != null) ...[
            const SizedBox(height: BirkaTokens.spaceSm),
            Text(
              rate,
              style: styles.caption.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: BirkaTokens.spaceMd),
          BirkaButton(
            label: t.inbox.makeTransfer,
            onPressed: busy ? null : () => unawaited(cubit.makeTransfer(pair)),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          BirkaButton(
            label: t.inbox.notTransfer,
            quiet: true,
            onPressed: busy
                ? null
                : () {
                    unawaited(cubit.notTransfer(pair));
                    onSay(t.inbox.keptIncome);
                  },
          ),
        ],
      ),
    );
  }
}

/// One side of a pair: its day and account, its money and its name.
class _Side extends StatelessWidget {
  const _Side({
    required this.transaction,
    required this.state,
    required this.thisYear,
  });

  final Transaction transaction;
  final InboxState state;
  final int thisYear;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final note = transaction.note.trim();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BirkaTokens.spaceMd,
        vertical: BirkaTokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(
          Radius.circular(BirkaTokens.radiusMd),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            placeLabel(transaction, state, thisYear),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: styles.caption.copyWith(color: colors.textMuted),
          ),
          AmountText(
            amountLabel(transaction),
            tone: toneOf(transaction),
            style: styles.heading,
          ),
          Text(
            [
              if (note.isNotEmpty) note,
              if (transaction.importId != null) t.inbox.fromStatement,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: styles.caption.copyWith(color: colors.textSubtle),
          ),
        ],
      ),
    );
  }
}
