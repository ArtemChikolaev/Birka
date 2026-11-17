import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:limits_common/limits_common.dart';
import 'package:limits_jaspr/src/presentation/components/limit_bits.dart';
import 'package:rates/rates.dart';

/// The page of the limits on the site (ADR 0033), as the boards «Лимиты на
/// сайте» draw it: the limits of the month with what is left of each and the
/// pace of one near its end, the categories without a limit that spent, and
/// the limits from averages. A wide page keeps how many are within and the
/// days left at the side; a narrow one puts them on top.
///
/// It needs a [LimitsCubit] above it.
class LimitsPage extends StatefulComponent {
  /// Creates the page.
  const LimitsPage({
    required this.backHref,
    required this.addHref,
    required this.suggestHref,
    required this.hrefOf,
    this.said,
    super.key,
  });

  /// What the page says as it opens, such as a limit that a form set.
  final String? said;

  /// Where the way back leads.
  final String backHref;

  /// Where the form of a new limit opens.
  final String addHref;

  /// Where the limits from averages open.
  final String suggestHref;

  /// Where the form of the limit of a category opens, by its id: its limit,
  /// or a new one for it.
  final String Function(String categoryId) hrefOf;

  @override
  State<LimitsPage> createState() => _LimitsPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    ...limitNoteStyles,
    css('.limits').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
      },
    ),
    css('.limits__add').styles(raw: {'display': 'flex', 'flex': 'none'}),
    css('.limits__stats').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'repeat(2, minmax(0, 1fr))',
      },
    ),
    css('.limits__stats--column').styles(
      raw: {'grid-template-columns': 'minmax(0, 1fr)'},
    ),
    css('.limits-stat').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
      },
    ),
    css('.limits-stat__label, .limits-stat__caption').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.limits-stat__caption--over').styles(
      raw: {'color': 'var(--color-negative)'},
    ),
    css('.limits__section').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.limits__section > .section-label').styles(
      raw: {'color': 'var(--color-text-muted)', 'padding': '0 var(--space-xs)'},
    ),
    css('.limits__note').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'margin': '0',
        'padding': '0 var(--space-xs)',
      },
    ),
    css('.limit-row').styles(
      raw: {
        'align-items': 'flex-start',
        'padding-bottom': 'var(--space-sm)',
        'padding-top': 'var(--space-sm)',
        'text-decoration': 'none',
      },
    ),
    css('.limit-row__body').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'min-width': '0',
      },
    ),
    css('.limit-row__top').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'min-height': '36px',
      },
    ),
    css('.limit-row__figures').styles(
      raw: {
        'align-items': 'flex-end',
        'display': 'flex',
        'flex': 'none',
        'flex-direction': 'column',
      },
    ),
    css('.limit-row__of').styles(raw: {'color': 'var(--color-text-muted)'}),
    css('.limit-row__pace').styles(
      raw: {'color': 'var(--color-palette-amber)'},
    ),
    css('.limits__empty').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
        'padding': 'var(--space-xxl) var(--space-lg)',
        'text-align': 'center',
      },
    ),
    css('.limits__empty-title').styles(
      raw: {'margin': 'var(--space-xs) 0 0'},
    ),
    css('.limits__empty-text').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'margin': '0 0 var(--space-xs)',
        'max-width': '420px',
      },
    ),
    css('.limits__empty .birka-button').styles(
      raw: {'width': 'min(100%, 320px)'},
    ),
  ];
}

class _LimitsPageState extends State<LimitsPage> {
  String? _said;
  var _toasts = 0;

  @override
  void initState() {
    super.initState();
    _said = component.said;
  }

  @override
  Component build(BuildContext context) {
    final said = _said;
    return BlocBuilder<LimitsCubit, LimitsState>(
      builder: (context, state) => div(classes: 'limits', [
        _header(),
        switch (state.status) {
          LimitsStatus.loading => const BirkaPlaceholder(),
          LimitsStatus.failed => GlassNotice(text: t.limits.form.failed),
          LimitsStatus.ready when state.limits.isEmpty => _empty(),
          LimitsStatus.ready => BirkaSplit(
            asideWidth: 340,
            asideWhenNarrow: false,
            main: _main(context, state),
            aside: [_stats(state, column: true), _suggest(state)],
          ),
        },
        if (said != null)
          GlassToast(
            said,
            key: ValueKey(_toasts),
            onGone: () => setState(() {
              _said = null;
              _toasts++;
            }),
          ),
      ]),
    );
  }

  Component _header() {
    final label = t.limits.form.newTitle;
    return GlassPageHeader(
      leading: GlassIconButton(
        glyph: BirkaGlyph.back,
        label: t.limits.back,
        href: component.backHref,
      ),
      title: t.limits.title,
      trailing: div(classes: 'limits__add', [
        div(classes: 'birka-narrow-only', [
          GlassIconButton(
            glyph: BirkaGlyph.plus,
            label: label,
            href: component.addHref,
          ),
        ]),
        div(classes: 'birka-wide-only', [
          BirkaButton(label: label, href: component.addHref, compact: true),
        ]),
      ]),
    );
  }

  List<Component> _main(BuildContext context, LimitsState state) {
    final unrated = state.limits.any((limit) => limit.unrated);
    return [
      div(classes: 'birka-narrow-only', [_stats(state)]),
      section(classes: 'limits__section', [
        SectionLabel(limitMonthName(state.month)),
        GlassListGroup(
          children: [
            for (final progress in state.limits) _row(context, progress),
          ],
        ),
      ]),
      p(classes: 'text-caption limits__note', [
        .text(unrated ? t.limits.unrated : t.limits.footnote),
      ]),
      if (state.free.isNotEmpty)
        section(classes: 'limits__section', [
          SectionLabel(t.limits.noLimit),
          GlassListGroup(
            children: [
              for (final free in state.free) _free(context, state, free),
            ],
          ),
        ]),
      div(classes: 'birka-narrow-only', [_suggest(state)]),
    ];
  }

  Component _row(BuildContext context, LimitProgress progress) {
    String mask(String text) => HiddenAmounts.mask(context, text);
    final pace = limitPace(progress);
    final tone = progress.state.name;
    return a(
      classes: 'glass-row glass-row--action limit-row',
      href: component.hrefOf(progress.category.id),
      [
        limitBadge(progress.category),
        span(classes: 'limit-row__body', [
          span(classes: 'limit-row__top', [
            span(classes: 'glass-row__text', [
              span(classes: 'text-body-strong glass-row__line', [
                .text(progress.category.name),
              ]),
              span(
                classes:
                    'text-caption glass-row__line limit-note '
                    'limit-note--$tone',
                [.text(mask(limitNote(progress)))],
              ),
            ]),
            span(classes: 'limit-row__figures', [
              span(classes: 'text-body-strong amount', [
                .text(mask(limitSpent(progress))),
              ]),
              span(classes: 'text-caption limit-row__of', [
                .text(mask(limitOf(progress))),
              ]),
            ]),
          ]),
          BirkaMeter(
            value: progress.share,
            label: limitMeter(progress),
            color: limitColor(progress.state),
            height: 6,
          ),
          if (pace != null)
            span(classes: 'text-caption limit-row__pace', [.text(pace)]),
        ]),
      ],
    );
  }

  Component _free(BuildContext context, LimitsState state, FreeCategory free) {
    final href = component.hrefOf(free.category.id);
    return GlassListRow(
      key: ValueKey(free.category.id),
      leading: limitBadge(free.category),
      title: free.category.name,
      subtitle: HiddenAmounts.mask(context, freeNote(free, state.today)),
      href: href,
      action: BirkaButton(
        label: t.limits.set,
        href: href,
        quiet: true,
        compact: true,
      ),
    );
  }

  Component _stats(LimitsState state, {bool column = false}) {
    Component stat(
      String label,
      String value,
      String note, {
      bool over = false,
    }) => div(classes: 'glass limits-stat', [
      span(classes: 'text-caption limits-stat__label', [.text(label)]),
      span(classes: 'text-title limits-stat__value', [.text(value)]),
      span(
        classes: over
            ? 'text-caption limits-stat__caption limits-stat__caption--over'
            : 'text-caption limits-stat__caption',
        [.text(note)],
      ),
    ]);
    return div(
      classes: column ? 'limits__stats limits__stats--column' : 'limits__stats',
      [
        stat(
          t.limits.withinTitle,
          limitsWithin(state),
          limitsOverNote(state),
          over: state.over > 0,
        ),
        stat(
          t.limits.monthEndTitle,
          limitsDaysLeft(state),
          limitsRestart(state),
        ),
      ],
    );
  }

  Component _suggest(LimitsState state) => GlassListGroup(
    children: [
      GlassListRow(
        leading: const GlyphBadge(
          glyph: BirkaGlyph.gauge,
          color: 'var(--color-accent)',
        ),
        title: t.limits.suggest,
        subtitle: suggestionsFrom(state.month),
        href: component.suggestHref,
        chevron: true,
      ),
    ],
  );

  Component _empty() => div(classes: 'limits__empty', [
    const GlyphBadge(
      glyph: BirkaGlyph.gauge,
      color: 'var(--color-accent)',
      size: 64,
    ),
    h2(classes: 'text-heading limits__empty-title', [
      .text(t.limits.emptyTitle),
    ]),
    p(classes: 'text-body limits__empty-text', [.text(t.limits.emptyText)]),
    BirkaButton(label: t.limits.suggest, href: component.suggestHref),
    BirkaButton(label: t.limits.manual, href: component.addHref, quiet: true),
  ]);
}
