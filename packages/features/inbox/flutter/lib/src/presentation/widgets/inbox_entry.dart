import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:l10n/l10n.dart';

/// The color of what waits for the person.
const _waits = Color(BirkaTokens.colorPaletteAmber);

/// The way to the inbox on the overview, as its board draws it (ADR 0022,
/// point 9): a strip that says how much waits and after which import, which
/// [onOpen] follows. It closes, with the space under it, once nothing waits,
/// and opens when an import leaves something. It needs an
/// [InboxSummaryCubit] above it.
class InboxCard extends StatelessWidget {
  /// Creates the strip.
  const InboxCard({required this.onOpen, super.key});

  /// Opens the inbox.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InboxSummaryCubit, InboxState>(
      builder: (context, state) => AnimatedColumn(
        children: [
          if (state.count > 0)
            Padding(
              key: const ValueKey('inbox'),
              padding: const EdgeInsets.only(bottom: BirkaTokens.spaceLg),
              child: _Strip(state: state, onOpen: onOpen),
            ),
        ],
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.state, required this.onOpen});

  final InboxState state;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final count = state.count;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BirkaTokens.spaceMd,
            vertical: BirkaTokens.spaceSm,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _waits.withValues(alpha: 0.14),
                _waits.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(BirkaTokens.radiusLg),
            ),
            border: Border.all(color: _waits.withValues(alpha: 0.26)),
          ),
          child: Row(
            children: [
              const GlyphBadge(
                glyph: BirkaGlyph.inbox,
                color: _waits,
                size: 40,
              ),
              const SizedBox(width: BirkaTokens.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.inbox.entryTitle(n: count, count: formatCount(count)),
                      style: styles.bodyStrong.copyWith(color: colors.text),
                    ),
                    Text(
                      entryLine(state),
                      style: styles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BirkaTokens.spaceXs),
              BirkaIcon(BirkaGlyph.chevron, size: 18, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// The way to the inbox in More, as its board draws it (ADR 0022, point 9):
/// a row of glass that says how much waits and after which import, or that
/// all is sorted, with the count at its end, which [onOpen] follows. It
/// needs an [InboxSummaryCubit] above it.
class InboxTile extends StatelessWidget {
  /// Creates the row.
  const InboxTile({required this.onOpen, super.key});

  /// Opens the inbox.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return BlocBuilder<InboxSummaryCubit, InboxState>(
      builder: (context, state) {
        final count = state.count;
        // What waits is unknown until the ledger is read, or when it is not.
        final known = !state.loading && !state.failed;
        // The line comes once the ledger is read, without a jump.
        return AnimatedSize(
          duration: BirkaMotion.reduced(context)
              ? Duration.zero
              : BirkaMotion.base,
          curve: BirkaMotion.standardCurve,
          alignment: Alignment.topCenter,
          child: GlassListGroup(
            children: [
              GlassListRow(
                title: t.inbox.title,
                subtitle: switch (known) {
                  false => null,
                  true when count > 0 => waitingLabel(state),
                  true => t.inbox.emptyTitle,
                },
                subtitleLines: 2,
                leading: const GlyphBadge(
                  glyph: BirkaGlyph.inbox,
                  color: _waits,
                  size: 34,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (known) ...[
                      _Count(count),
                      const SizedBox(width: BirkaTokens.spaceXs),
                    ],
                    BirkaIcon(
                      BirkaGlyph.chevron,
                      size: 18,
                      color: colors.textSubtle,
                    ),
                  ],
                ),
                onTap: onOpen,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// How much waits, in the color of what waits, or quiet at none.
class _Count extends StatelessWidget {
  const _Count(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final waits = count > 0;
    return AnimatedContainer(
      duration: BirkaMotion.reduced(context) ? Duration.zero : BirkaMotion.fast,
      constraints: const BoxConstraints(minWidth: 24),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: BirkaTokens.spaceXs),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: waits ? _waits.withValues(alpha: 0.18) : colors.surfaceRaised,
        borderRadius: const BorderRadius.all(
          Radius.circular(BirkaTokens.radiusPill),
        ),
      ),
      child: Text(
        formatCount(count),
        style: BirkaTextStyles.of(context).caption.copyWith(
          color: waits ? _waits : colors.textMuted,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
