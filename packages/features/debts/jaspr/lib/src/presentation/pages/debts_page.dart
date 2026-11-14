import 'package:debts_common/debts_common.dart';
import 'package:debts_jaspr/src/presentation/components/debt_badge.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:money/money.dart';

/// The list of debts (ADR 0029): what others owe the person and what the
/// person owes, each added up, and the settled debts in a fold. On a wide
/// page a [side] stands beside the list, such as the card of the [picked]
/// debt.
///
/// It needs a [DebtsCubit] above it.
class DebtsPage extends StatefulComponent {
  /// Creates the page.
  const DebtsPage({
    required this.addHref,
    required this.hrefOf,
    this.picked,
    this.side,
    super.key,
  });

  /// Where the form of a new debt opens.
  final String addHref;

  /// Where the card of the debt with this id opens.
  final String Function(String id) hrefOf;

  /// The debt whose card or form stands beside the list.
  final String? picked;

  /// What stands beside the list on a wide page.
  final Component? side;

  @override
  State<DebtsPage> createState() => _DebtsPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.debts__totals').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'repeat(2, minmax(0, 1fr))',
      },
    ),
    css('.debts__total').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
      },
    ),
    css('.debts__total-label, .debts__total-people').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.debts__group').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.debts__group > .section-label').styles(
      raw: {'padding': '0 var(--space-xs)'},
    ),
    css('.debts__amount').styles(
      raw: {
        'align-items': 'flex-end',
        'display': 'flex',
        'flex-direction': 'column',
      },
    ),
    css('.debts__amount-note').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.debts__fold-toggle').styles(
      raw: {
        'align-items': 'center',
        'align-self': 'flex-start',
        'background': 'none',
        'border': '0',
        'color': 'inherit',
        'cursor': 'pointer',
        'display': 'flex',
        'font': 'inherit',
        'gap': 'var(--space-xxs)',
        'padding': '0 var(--space-xs)',
      },
    ),
    css('.debts__fold-toggle .birka-icon').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'height': '16px',
        'transition': 'transform var(--duration-base) var(--easing-standard)',
        'width': '16px',
      },
    ),
    css('.debts__fold-toggle[aria-expanded="true"] .birka-icon').styles(
      raw: {'transform': 'rotate(90deg)'},
    ),
    css('.debts__note').styles(
      raw: {'color': 'var(--color-text-subtle)', 'margin': '0'},
    ),
    // A wide page keeps the welcome as narrow as the column of a phone.
    css('.debts__empty').styles(
      raw: {
        'align-items': 'center',
        'align-self': 'center',
        'box-sizing': 'border-box',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
        'max-width': '480px',
        'padding-top': 'var(--space-xxl)',
        'text-align': 'center',
        'width': '100%',
      },
    ),
    css('.debts__empty-title').styles(raw: {'margin': 'var(--space-xs) 0 0'}),
    css('.debts__empty-text').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'margin': '0 0 var(--space-sm)',
        'max-width': '420px',
      },
    ),
    css('.debts__empty .birka-button').styles(raw: {'align-self': 'stretch'}),
  ];
}

class _DebtsPageState extends State<DebtsPage> {
  var _closedOpen = false;

  @override
  Component build(BuildContext context) {
    return BlocBuilder<DebtsCubit, DebtsState>(
      builder: (context, state) {
        final header = GlassPageHeader(
          title: t.debts.title,
          trailing: GlassIconButton(
            glyph: BirkaGlyph.plus,
            label: t.debts.newDebt,
            href: component.addHref,
          ),
        );
        final body = switch (state.status) {
          DebtsStatus.loading => const <Component>[],
          DebtsStatus.failed => [GlassNotice(text: t.debts.failed)],
          DebtsStatus.ready when state.isEmpty => [_empty()],
          DebtsStatus.ready => _sections(state),
        };
        final side = component.side;
        if (side == null) return BirkaColumn(children: [header, ...body]);
        return BirkaColumn(
          children: [
            header,
            BirkaSplit(asideWidth: 420, main: body, aside: [side]),
          ],
        );
      },
    );
  }

  List<Component> _sections(DebtsState state) {
    final closed = state.closed;
    return [
      div(classes: 'debts__totals', [
        _total(
          t.debts.owedToMe,
          state.owedTotal,
          state.owed.length,
          AmountTone.positive,
          state.base,
        ),
        _total(
          t.debts.myDebts,
          state.mineTotal,
          state.mine.length,
          AmountTone.neutral,
          state.base,
        ),
      ]),
      for (final (title, debts, tone) in [
        (t.debts.owedToMe, state.owed, AmountTone.positive),
        (t.debts.myDebts, state.mine, AmountTone.neutral),
      ])
        if (debts.isNotEmpty)
          section(classes: 'debts__group', [
            SectionLabel(title),
            GlassListGroup(
              children: [
                for (final debt in debts) _row(debt, state, tone),
              ],
            ),
          ]),
      if (closed.isNotEmpty)
        section(classes: 'debts__group', [
          button(
            classes: 'debts__fold-toggle',
            type: ButtonType.button,
            attributes: {'aria-expanded': '$_closedOpen'},
            onClick: () => setState(() => _closedOpen = !_closedOpen),
            [
              SectionLabel(t.debts.closed(n: closed.length)),
              const BirkaIcon(BirkaGlyph.chevron),
            ],
          ),
          BirkaFold(
            open: _closedOpen,
            children: [
              GlassListGroup(
                children: [
                  for (final debt in closed)
                    _row(debt, state, AmountTone.muted),
                ],
              ),
            ],
          ),
        ]),
      p(classes: 'text-caption debts__note', [
        .text(
          state.hasOtherCurrencies ? t.debts.captionRates : t.debts.caption,
        ),
      ]),
    ];
  }

  Component _total(
    String label,
    Money? amount,
    int people,
    AmountTone tone,
    Currency base,
  ) {
    final shown = amount ?? Money.zero(base);
    return GlassSurface(
      child: div(classes: 'debts__total', [
        span(classes: 'text-caption debts__total-label', [.text(label)]),
        AmountText(
          amount == null ? '—' : formatMoney(shown),
          tone: people == 0 ? AmountTone.neutral : tone,
          textClass: 'text-heading',
        ),
        span(classes: 'text-caption debts__total-people', [
          .text(t.debts.people(n: people)),
        ]),
      ]),
    );
  }

  Component _row(Debt debt, DebtsState state, AmountTone tone) {
    final line = debtLine(debt, today: state.today);
    final note = debtAmountNote(debt, state);
    final shown = debt.closed ? debt.total : debt.left;
    return GlassListRow(
      key: ValueKey(debt.id),
      leading: DebtBadge(debt.account),
      title: debt.name,
      subtitle: line.text,
      subtitleColor: debtToneColor(line.tone),
      trailing: span(classes: 'debts__amount', [
        AmountText(
          debtAmount(shown),
          tone: tone,
          textClass: 'text-body-strong',
        ),
        if (note != null)
          AmountText(note, tone: AmountTone.muted, textClass: 'text-caption'),
      ]),
      href: component.hrefOf(debt.id),
      picked: debt.id == component.picked,
    );
  }

  Component _empty() {
    return div(classes: 'debts__empty', [
      const GlyphBadge(
        glyph: BirkaGlyph.people,
        color: 'var(--color-accent)',
        size: 72,
      ),
      h2(classes: 'text-heading debts__empty-title', [
        .text(t.debts.emptyTitle),
      ]),
      p(classes: 'text-body debts__empty-text', [.text(t.debts.emptyText)]),
      BirkaButton(label: t.debts.add, href: component.addHref),
    ]);
  }
}
