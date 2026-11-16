import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:limits_common/limits_common.dart';
import 'package:limits_flutter/src/presentation/widgets/limit_bits.dart';
import 'package:rates/rates.dart';

/// The limits of the month at the bottom of the card «Траты в ноябре» of the
/// overview (ADR 0033): the three that need the person most, over first, or
/// an invitation while there are none. It draws the line above itself once
/// the limits are counted, and grows into the card.
///
/// It needs a [LimitsCubit] above it, and counts again when the app comes
/// back, as a new day may have come.
class LimitsOverviewPart extends StatefulWidget {
  /// Creates the part.
  const LimitsOverviewPart({
    required this.onOpen,
    required this.onSuggest,
    super.key,
  });

  /// Opens the page «Лимиты».
  final VoidCallback onOpen;

  /// Opens the limits offered from averages.
  final VoidCallback onSuggest;

  @override
  State<LimitsOverviewPart> createState() => _LimitsOverviewPartState();
}

class _LimitsOverviewPartState extends State<LimitsOverviewPart> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<LimitsCubit>().refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return BlocBuilder<LimitsCubit, LimitsState>(
      builder: (context, state) => AnimatedSize(
        duration: BirkaMotion.reduced(context)
            ? Duration.zero
            : BirkaMotion.base,
        curve: BirkaMotion.standardCurve,
        alignment: Alignment.topCenter,
        child: state.status != LimitsStatus.ready
            ? const SizedBox.shrink()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: BirkaTokens.spaceMd),
                  SizedBox(
                    height: 1,
                    child: ColoredBox(color: colors.hairline),
                  ),
                  const SizedBox(height: BirkaTokens.spaceSm),
                  _part(context, state),
                ],
              ),
      ),
    );
  }

  Widget _part(BuildContext context, LimitsState state) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    if (state.limits.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(t.limits.inviteTitle, color: colors.textMuted),
          const SizedBox(height: BirkaTokens.spaceXs),
          Text(
            t.limits.emptyText,
            style: styles.body.copyWith(color: colors.textSecondary),
          ),
          AccentLink(
            label: t.limits.inviteAction,
            onTap: widget.onSuggest,
            expand: true,
          ),
        ],
      );
    }
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: SectionLabel(
                    limitsTitle(state.today),
                    color: colors.textMuted,
                  ),
                ),
                FadingText(
                  limitsSummary(state),
                  style: styles.caption.copyWith(
                    color: state.over > 0 ? colors.negative : colors.textMuted,
                  ),
                ),
              ],
            ),
            AnimatedColumn(
              children: [
                for (final progress in state.limits.take(3))
                  _Limit(
                    key: ValueKey(progress.category.id),
                    progress: progress,
                  ),
              ],
            ),
            AccentLink(
              label: t.limits.all(n: state.limits.length),
              onTap: widget.onOpen,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Limit extends StatelessWidget {
  const _Limit({required this.progress, super.key});

  final LimitProgress progress;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: BirkaTokens.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.bodyStrong.copyWith(color: colors.text),
                ),
              ),
              const SizedBox(width: BirkaTokens.spaceXs),
              FadingText(
                HiddenAmounts.mask(context, limitFigures(progress)),
                style: styles.caption.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceXxs),
          BirkaMeter(
            value: progress.share,
            color: limitColor(context, progress.state),
            label: limitMeter(progress),
            height: 6,
            fromEmpty: true,
          ),
          const SizedBox(height: BirkaTokens.spaceXxs),
          FadingText(
            HiddenAmounts.mask(context, limitOverviewNote(progress)),
            style: styles.caption.copyWith(
              color: limitNoteColor(context, progress.state),
            ),
          ),
        ],
      ),
    );
  }
}
