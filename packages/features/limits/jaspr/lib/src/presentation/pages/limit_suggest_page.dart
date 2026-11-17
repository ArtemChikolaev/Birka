import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:limits_common/limits_common.dart';
import 'package:rates/rates.dart';

/// The limits offered from the averages of three months on the site
/// (ADR 0033): the steady categories come checked and the others say why
/// they do not, and a wide page tells at the side how the averages count.
/// Without a full month to count from it says when the averages come.
///
/// It needs a [LimitSuggestCubit] above it.
class LimitSuggestPage extends StatelessComponent {
  /// Creates the page.
  const LimitSuggestPage({
    required this.onClose,
    required this.manualHref,
    required this.onDone,
    super.key,
  });

  /// Leaves the page.
  final VoidCallback onClose;

  /// Where the form of a new limit opens.
  final String manualHref;

  /// Called once the checked limits are set, with what the next page says.
  final ValueChanged<String> onDone;

  @override
  Component build(BuildContext context) {
    return BlocConsumer<LimitSuggestCubit, LimitSuggestState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (_, state) {
        if (state.status == LimitSuggestStatus.saved) {
          onDone(suggestionsDone(state));
        }
      },
      builder: (context, state) => switch (state.status) {
        LimitSuggestStatus.loading => const BirkaPlaceholder(),
        LimitSuggestStatus.short => _quiet(
          const GlyphBadge(
            glyph: BirkaGlyph.calendar,
            color: 'var(--color-palette-amber)',
            size: 64,
          ),
          t.limits.suggestions.shortTitle,
          suggestionsShort(state),
          BirkaButton(label: t.limits.manual, href: manualHref, quiet: true),
        ),
        LimitSuggestStatus.nothing => _quiet(
          const GlyphBadge(
            glyph: BirkaGlyph.gauge,
            color: 'var(--color-accent)',
            size: 64,
          ),
          t.limits.suggestions.nothing,
          null,
          null,
        ),
        _ => _list(context, state),
      },
    );
  }

  /// The page while there is nothing to offer.
  Component _quiet(
    GlyphBadge badge,
    String title,
    String? text,
    Component? action,
  ) {
    final body = [
      badge,
      h2(classes: 'text-heading limits__empty-title', [.text(title)]),
      if (text != null)
        p(classes: 'text-body limits__empty-text', [.text(text)]),
      ?action,
    ];
    return BirkaForm(
      title: t.limits.suggestions.title,
      closeLabel: t.app.close,
      onClose: onClose,
      submitLabel: null,
      onSubmit: null,
      children: [div(classes: 'limits__empty', body)],
    );
  }

  Component _list(BuildContext context, LimitSuggestState state) {
    final cubit = context.read<LimitSuggestCubit>();
    String mask(String text) => HiddenAmounts.mask(context, text);
    return BirkaForm(
      title: t.limits.suggestions.title,
      closeLabel: t.app.close,
      onClose: onClose,
      submitLabel: suggestionsButton(state),
      onSubmit: () => unawaited(cubit.save()),
      ready: state.canSave,
      submitting:
          state.status == LimitSuggestStatus.saving ||
          state.status == LimitSuggestStatus.saved,
      failure: state.status == LimitSuggestStatus.failed
          ? t.limits.form.failed
          : null,
      aside: [
        div(classes: 'birka-wide-only', [
          GlassSteps(
            title: t.limits.suggestions.howTitle,
            points: [
              suggestionsMonths(state),
              mask(suggestionsStep(state)),
              t.limits.suggestions.howUnchecked,
            ],
          ),
        ]),
      ],
      children: [
        p(classes: 'text-body limit-suggest__text', [
          .text(mask(suggestionsText(state))),
        ]),
        GlassListGroup(
          children: [
            for (final suggestion in state.suggestions)
              _row(context, cubit, state, suggestion),
          ],
        ),
        p(classes: 'text-caption limits__note', [
          .text(t.limits.suggestions.later),
        ]),
      ],
    );
  }

  Component _row(
    BuildContext context,
    LimitSuggestCubit cubit,
    LimitSuggestState state,
    LimitSuggestion suggestion,
  ) {
    final id = suggestion.category.id;
    final picked = state.picked.contains(id);
    return GlassListRow(
      key: ValueKey(id),
      leading: BirkaCheckbox(
        checked: picked,
        label: suggestion.category.name,
        onChanged: (_) => cubit.toggle(id),
      ),
      title: suggestion.category.name,
      subtitle: HiddenAmounts.mask(context, suggestionNote(suggestion)),
      trailing: span(
        classes: picked
            ? 'text-body-strong amount limit-suggest__offer'
            : 'text-body-strong amount limit-suggest__offer '
                  'limit-suggest__offer--off',
        [.text(HiddenAmounts.mask(context, formatMoney(suggestion.offer)))],
      ),
    );
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.limit-suggest__text').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css('.limit-suggest__offer').styles(
      raw: {'flex': 'none', 'transition': 'color var(--duration-fast)'},
    ),
    css('.limit-suggest__offer--off').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
  ];
}
