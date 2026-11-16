import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:limits_common/limits_common.dart';
import 'package:limits_flutter/src/presentation/widgets/limit_bits.dart';
import 'package:rates/rates.dart';

/// Limits offered from the averages of three months, as a sheet (ADR 0033):
/// the steady categories come checked and the others say why they do not.
///
/// It needs a [LimitSuggestCubit] above it. Once the limits are set, it says
/// so in a toast and calls [onClose]; [onManual] opens the form of a limit
/// when there is no full month to count from.
class LimitSuggestPage extends StatelessWidget {
  /// Creates the sheet.
  const LimitSuggestPage({
    required this.onClose,
    required this.onManual,
    super.key,
  });

  /// Closes the sheet.
  final VoidCallback onClose;

  /// Opens the form of a new limit.
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: BlocBuilder<LimitSuggestCubit, LimitSuggestState>(
            builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BirkaTokens.spaceLg,
                    BirkaTokens.spaceXs,
                    BirkaTokens.spaceLg,
                    BirkaTokens.spaceSm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.limits.suggestions.title,
                          style: styles.heading.copyWith(color: colors.text),
                        ),
                      ),
                      GlassIconButton(
                        glyph: BirkaGlyph.close,
                        label: t.app.close,
                        glass: false,
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: switch (state.status) {
                    LimitSuggestStatus.loading => const SizedBox.shrink(),
                    LimitSuggestStatus.short => _Short(
                      state: state,
                      onManual: onManual,
                    ),
                    LimitSuggestStatus.nothing => Padding(
                      padding: const EdgeInsets.all(BirkaTokens.spaceLg),
                      child: Text(
                        t.limits.suggestions.nothing,
                        textAlign: TextAlign.center,
                        style: styles.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    _ => _List(state: state),
                  },
                ),
                if (state.suggestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BirkaTokens.spaceLg,
                      BirkaTokens.spaceXs,
                      BirkaTokens.spaceLg,
                      BirkaTokens.spaceMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.status == LimitSuggestStatus.failed) ...[
                          Text(
                            t.limits.form.failed,
                            textAlign: TextAlign.center,
                            style: styles.caption.copyWith(
                              color: colors.negative,
                            ),
                          ),
                          const SizedBox(height: BirkaTokens.spaceXs),
                        ],
                        BirkaButton(
                          label: suggestionsButton(state),
                          onPressed: state.canSave
                              ? () => unawaited(
                                  context.read<LimitSuggestCubit>().save(),
                                )
                              : null,
                          done: state.status == LimitSuggestStatus.saved,
                          onDone: () {
                            showGlassToast(context, suggestionsDone(state));
                            onClose();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.state});

  final LimitSuggestState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LimitSuggestCubit>();
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return ScrollEdgeFade(
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BirkaTokens.spaceLg,
          vertical: BirkaTokens.spaceXs,
        ),
        children: [
          Text(
            HiddenAmounts.mask(context, suggestionsText(state)),
            style: styles.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          GlassListGroup(
            children: [
              for (final suggestion in state.suggestions)
                GlassListRow(
                  key: ValueKey(suggestion.category.id),
                  leading: ExcludeSemantics(
                    child: BirkaCheckbox(
                      checked: state.picked.contains(suggestion.category.id),
                      label: suggestion.category.name,
                      onChanged: (_) => cubit.toggle(suggestion.category.id),
                    ),
                  ),
                  title: suggestion.category.name,
                  subtitle: HiddenAmounts.mask(
                    context,
                    suggestionNote(suggestion),
                  ),
                  subtitleColor: suggestion.picked ? null : colors.textMuted,
                  trailing: Text(
                    HiddenAmounts.mask(context, formatMoney(suggestion.offer)),
                    style: styles.bodyStrong.copyWith(
                      color: state.picked.contains(suggestion.category.id)
                          ? colors.text
                          : colors.textMuted,
                    ),
                  ),
                  onTap: () => cubit.toggle(suggestion.category.id),
                ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceSm),
          Text(
            t.limits.suggestions.later,
            style: styles.caption.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Short extends StatelessWidget {
  const _Short({required this.state, required this.onManual});

  final LimitSuggestState state;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        BirkaTokens.spaceLg,
        BirkaTokens.spaceXxl,
        BirkaTokens.spaceLg,
        BirkaTokens.spaceLg,
      ),
      children: [
        Center(
          child: ExcludeSemantics(
            child: GlyphBadge(
              glyph: BirkaGlyph.calendar,
              color: limitColor(context, LimitState.near),
              size: 64,
            ),
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceMd),
        Text(
          t.limits.suggestions.shortTitle,
          textAlign: TextAlign.center,
          style: styles.heading.copyWith(color: colors.text),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        Text(
          suggestionsShort(state),
          textAlign: TextAlign.center,
          style: styles.body.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: BirkaTokens.spaceLg),
        BirkaButton(label: t.limits.manual, quiet: true, onPressed: onManual),
      ],
    );
  }
}
