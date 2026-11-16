import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:limits_common/limits_common.dart';
import 'package:limits_flutter/src/presentation/widgets/limit_bits.dart';
import 'package:rates/rates.dart';

/// The page «Лимиты» (ADR 0033): what is left of each limit this month, over
/// first, the pace of one near its end, the categories without a limit and
/// the limits offered from averages.
///
/// It needs a [LimitsCubit] above it.
class LimitsPage extends StatelessWidget {
  /// Creates the page.
  const LimitsPage({
    required this.onBack,
    required this.onAdd,
    required this.onOpen,
    required this.onSuggest,
    super.key,
  });

  /// Called by the way back.
  final VoidCallback onBack;

  /// Opens the form of a new limit, of a category when given.
  final ValueChanged<String?> onAdd;

  /// Opens the form of the limit of a category, by its id.
  final ValueChanged<String> onOpen;

  /// Opens the limits offered from averages.
  final VoidCallback onSuggest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<LimitsCubit, LimitsState>(
            builder: (context, state) => ListView(
              padding: const EdgeInsets.fromLTRB(
                BirkaTokens.spaceLg,
                BirkaTokens.spaceXs,
                BirkaTokens.spaceLg,
                BirkaTokens.spaceXxl,
              ),
              children: [
                BackHeader(
                  label: t.limits.title,
                  backLabel: t.limits.back,
                  onBack: onBack,
                  trailing: GlassIconButton(
                    glyph: BirkaGlyph.plus,
                    label: t.limits.form.newTitle,
                    onPressed: () => onAdd(null),
                  ),
                ),
                const SizedBox(height: BirkaTokens.spaceLg),
                ...switch (state.status) {
                  LimitsStatus.loading => const <Widget>[],
                  LimitsStatus.failed => [const _Failure()],
                  LimitsStatus.ready when state.limits.isEmpty => [
                    _Empty(onSuggest: onSuggest, onAdd: () => onAdd(null)),
                  ],
                  LimitsStatus.ready => _ready(context, state),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _ready(BuildContext context, LimitsState state) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final unrated = state.limits.any((progress) => progress.unrated);
    return [
      Row(
        children: [
          Expanded(
            child: _Figure(
              label: t.limits.withinTitle,
              value: limitsWithin(state),
              note: limitsOverNote(state),
              noteColor: state.over > 0 ? colors.negative : colors.textMuted,
            ),
          ),
          const SizedBox(width: BirkaTokens.spaceSm),
          Expanded(
            child: _Figure(
              label: t.limits.monthEndTitle,
              value: limitsDaysLeft(state),
              note: limitsRestart(state),
              noteColor: colors.textSecondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: BirkaTokens.spaceLg),
      SectionLabel(limitMonthName(state.today)),
      const SizedBox(height: BirkaTokens.spaceXs),
      GlassListGroup(
        children: [
          for (final progress in state.limits)
            _LimitRow(
              key: ValueKey(progress.category.id),
              progress: progress,
              onTap: () => onOpen(progress.category.id),
            ),
        ],
      ),
      const SizedBox(height: BirkaTokens.spaceXs),
      Text(
        unrated
            ? '${t.limits.footnote} ${t.limits.unrated}'
            : t.limits.footnote,
        style: styles.caption.copyWith(color: colors.textMuted),
      ),
      if (state.free.isNotEmpty) ...[
        const SizedBox(height: BirkaTokens.spaceLg),
        SectionLabel(t.limits.noLimit),
        const SizedBox(height: BirkaTokens.spaceXs),
        GlassListGroup(
          children: [
            for (final free in state.free)
              GlassListRow(
                key: ValueKey(free.category.id),
                leading: CategoryBadge(free.category),
                title: free.category.name,
                subtitle: HiddenAmounts.mask(
                  context,
                  freeNote(free, state.today),
                ),
                trailing: BirkaButton(
                  label: t.limits.set,
                  quiet: true,
                  compact: true,
                  onPressed: () => onAdd(free.category.id),
                ),
              ),
          ],
        ),
      ],
      const SizedBox(height: BirkaTokens.spaceLg),
      GlassListGroup(
        children: [
          GlassListRow(
            leading: ExcludeSemantics(
              child: GlyphBadge(glyph: BirkaGlyph.gauge, color: colors.accent),
            ),
            title: t.limits.suggest,
            subtitle: suggestionsFrom(state.month),
            trailing: BirkaIcon(
              BirkaGlyph.chevron,
              size: 16,
              color: colors.textMuted,
            ),
            onTap: onSuggest,
          ),
        ],
      ),
    ];
  }
}

/// A card of the top: a label, a figure and a note.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.note,
    required this.noteColor,
  });

  final String label;
  final String value;
  final String note;
  final Color noteColor;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: styles.caption.copyWith(color: colors.textMuted)),
          const SizedBox(height: BirkaTokens.spaceXxs),
          FadingText(value, style: styles.heading.copyWith(color: colors.text)),
          const SizedBox(height: BirkaTokens.spaceXxs),
          FadingText(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: styles.caption.copyWith(color: noteColor),
          ),
        ],
      ),
    );
  }
}

/// A limit of the month: its icon, name and note, what the month took of
/// it, its bar and the pace of one near its end.
class _LimitRow extends StatelessWidget {
  const _LimitRow({required this.progress, required this.onTap, super.key});

  final LimitProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final pace = limitPace(progress);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BirkaTokens.spaceMd,
            vertical: BirkaTokens.spaceSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CategoryBadge(progress.category),
                  const SizedBox(width: BirkaTokens.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progress.category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: styles.bodyStrong.copyWith(color: colors.text),
                        ),
                        FadingText(
                          HiddenAmounts.mask(context, limitNoteShort(progress)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: styles.caption.copyWith(
                            color: limitNoteColor(context, progress.state),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: BirkaTokens.spaceXs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AmountText(
                        limitSpent(progress),
                        value: progress.spent.minorUnits,
                        style: styles.bodyStrong.copyWith(color: colors.text),
                      ),
                      Text(
                        HiddenAmounts.mask(context, limitOf(progress)),
                        style: styles.caption.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: BirkaTokens.spaceXs),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 48),
                child: BirkaMeter(
                  value: progress.share,
                  color: limitColor(context, progress.state),
                  label: limitMeter(progress),
                  height: 6,
                  fromEmpty: true,
                ),
              ),
              if (pace != null) ...[
                const SizedBox(height: BirkaTokens.spaceXxs),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 48),
                  child: Text(
                    pace,
                    style: styles.caption.copyWith(
                      color: const Color(BirkaTokens.colorPaletteAmber),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure();

  @override
  Widget build(BuildContext context) => Text(
    t.limits.form.failed,
    textAlign: TextAlign.center,
    style: BirkaTextStyles.of(
      context,
    ).body.copyWith(color: BirkaColors.of(context).negative),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onSuggest, required this.onAdd});

  final VoidCallback onSuggest;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: BirkaTokens.spaceXxl),
      child: Column(
        children: [
          ExcludeSemantics(
            child: GlyphBadge(
              glyph: BirkaGlyph.gauge,
              color: colors.accent,
              size: 72,
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          Text(
            t.limits.emptyTitle,
            textAlign: TextAlign.center,
            style: styles.heading.copyWith(color: colors.text),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          Text(
            t.limits.emptyText,
            textAlign: TextAlign.center,
            style: styles.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
          SizedBox(
            width: double.infinity,
            child: BirkaButton(label: t.limits.suggest, onPressed: onSuggest),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          SizedBox(
            width: double.infinity,
            child: BirkaButton(
              label: t.limits.manual,
              quiet: true,
              onPressed: onAdd,
            ),
          ),
        ],
      ),
    );
  }
}
