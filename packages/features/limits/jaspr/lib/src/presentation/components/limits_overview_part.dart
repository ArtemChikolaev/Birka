import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:limits_common/limits_common.dart';
import 'package:limits_jaspr/src/presentation/components/limit_bits.dart';
import 'package:rates/rates.dart';

/// The limits of the month at the bottom of the card of the spending on the
/// overview of the site (ADR 0033): the three that need the person most,
/// over first, or an invitation while there are none. It draws the line over
/// itself once the limits are counted, so that the card never ends in a line
/// with nothing under it.
///
/// It needs a [LimitsCubit] above it.
class LimitsOverviewPart extends StatelessComponent {
  /// Creates the part.
  const LimitsOverviewPart({
    required this.href,
    required this.suggestHref,
    super.key,
  });

  /// Where the page of the limits opens.
  final String href;

  /// Where the limits from averages open.
  final String suggestHref;

  @override
  Component build(BuildContext context) {
    return BlocBuilder<LimitsCubit, LimitsState>(
      builder: (context, state) {
        if (state.status != LimitsStatus.ready) return const div([]);
        if (state.limits.isEmpty) {
          return div(classes: 'limits-part', [
            const BirkaRule(),
            SectionLabel(t.limits.inviteTitle),
            p(classes: 'text-body limits-part__text', [
              .text(t.limits.emptyText),
            ]),
            BirkaLinkRow(label: t.limits.inviteAction, href: suggestHref),
          ]);
        }
        return div(classes: 'limits-part', [
          const BirkaRule(),
          div(classes: 'limits-part__head', [
            SectionLabel(limitsTitle(state.today)),
            span(
              classes: state.over > 0
                  ? 'text-caption limits-part__summary '
                        'limits-part__summary--over'
                  : 'text-caption limits-part__summary',
              [.text(limitsSummary(state))],
            ),
          ]),
          for (final progress in state.limits.take(3)) _line(context, progress),
          BirkaLinkRow(
            label: t.limits.all(n: state.limits.length),
            href: href,
          ),
        ]);
      },
    );
  }

  Component _line(BuildContext context, LimitProgress progress) {
    String mask(String text) => HiddenAmounts.mask(context, text);
    return div(classes: 'limit-line', [
      span(classes: 'limit-line__top', [
        span(classes: 'text-body-strong limit-line__name', [
          .text(progress.category.name),
        ]),
        span(classes: 'text-caption amount limit-line__figures', [
          .text(mask(limitFigures(progress))),
        ]),
      ]),
      BirkaMeter(
        value: progress.share,
        label: limitMeter(progress),
        color: limitColor(progress.state),
        height: 6,
      ),
      span(
        classes: 'text-caption limit-note limit-note--${progress.state.name}',
        [.text(mask(limitOverviewNote(progress)))],
      ),
    ]);
  }

  /// The styles of the part.
  @css
  static List<StyleRule> get styles => [
    ...limitNoteStyles,
    css('.limits-part').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
        'margin-top': 'var(--space-md)',
      },
    ),
    css('.limits-part > .birka-rule').styles(
      raw: {'margin-bottom': 'var(--space-xxs)'},
    ),
    css('.limits-part .section-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.limits-part__head').styles(
      raw: {
        'align-items': 'baseline',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
      },
    ),
    css('.limits-part__summary').styles(
      raw: {'color': 'var(--color-text-muted)', 'white-space': 'nowrap'},
    ),
    css('.limits-part__summary--over').styles(
      raw: {'color': 'var(--color-negative)'},
    ),
    css('.limits-part__text').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css('.limit-line').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
      },
    ),
    css('.limit-line__top').styles(
      raw: {
        'align-items': 'baseline',
        'display': 'flex',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.limit-line__name').styles(
      raw: {
        'flex': '1 1 auto',
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.limit-line__figures').styles(
      raw: {'color': 'var(--color-text-secondary)', 'flex': 'none'},
    ),
  ];
}
