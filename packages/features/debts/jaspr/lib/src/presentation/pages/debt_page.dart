import 'package:debts_common/debts_common.dart';
import 'package:debts_jaspr/src/presentation/components/debt_badge.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// The card of a debt (ADR 0029): what is left of what, the bar of what came
/// back, its day, the return in a fold under the actions, more money, and
/// its steps. Beside the list on a wide page it [closes] with a cross.
///
/// It needs a [DebtsCubit] above it. A debt that goes takes the page back.
class DebtPage extends StatefulComponent {
  /// Creates the card of debt [id].
  const DebtPage({
    required this.id,
    required this.onBack,
    required this.editHref,
    required this.moreHref,
    required this.hrefOfOperation,
    this.closes = false,
    this.returnForm,
    this.returnOpen = false,
    super.key,
  });

  /// The debt.
  final String id;

  /// Called by the way back, and when the debt is gone.
  final VoidCallback onBack;

  /// Where the form of the terms opens.
  final String editHref;

  /// Where the form of more money on the debt opens.
  final String moreHref;

  /// Where the operation of a step opens, by its id.
  final String Function(String id) hrefOfOperation;

  /// Whether the way back closes the card, as it does beside the list.
  final bool closes;

  /// The form of a return, as the host builds it, which closes the fold
  /// with the function it gets.
  final Component Function(VoidCallback close)? returnForm;

  /// Whether the return stands open at first.
  final bool returnOpen;

  @override
  State<DebtPage> createState() => _DebtPageState();

  /// The styles of the card.
  @css
  static List<StyleRule> get styles => [
    css('.debt-card__summary').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'text-align': 'center',
      },
    ),
    css('.debt-card__badge').styles(
      raw: {'display': 'flex', 'position': 'relative'},
    ),
    // A settled debt gets a check on the corner of its person.
    css('.debt-card__check').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-accent)',
        'border': '3px solid var(--color-background)',
        'border-radius': '50%',
        'bottom': '-6px',
        'box-sizing': 'border-box',
        'color': 'var(--color-on-accent)',
        'display': 'flex',
        'height': '26px',
        'justify-content': 'center',
        'position': 'absolute',
        'right': '-6px',
        'width': '26px',
      },
    ),
    css('.debt-card__check .birka-icon').styles(
      raw: {'height': '14px', 'width': '14px'},
    ),
    css('.debt-card__name, .debt-card__line').styles(raw: {'margin': '0'}),
    css('.debt-card__line').styles(raw: {'color': 'var(--color-text-muted)'}),
    css('.debt-card__settled').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.debt-card__settled-head').styles(
      raw: {
        'align-items': 'baseline',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
      },
    ),
    css('.debt-card__share').styles(raw: {'color': 'var(--color-text-muted)'}),
    css('.debt-card__bar').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'border-radius': '4px',
        'height': '8px',
        'overflow': 'hidden',
      },
    ),
    // The bar grows from nothing once the card is in, over duration.roll.
    css('.debt-card__fill').styles(
      raw: {
        'animation':
            'debt-card-grow var(--duration-roll) var(--easing-standard)',
        'background': 'var(--color-accent)',
        'border-radius': '4px',
        'display': 'block',
        'height': '8px',
        'transform-origin': '0 50%',
        'transition': 'width var(--duration-roll) var(--easing-standard)',
      },
    ),
    css.keyframes('debt-card-grow', {
      'from': const Styles(raw: {'transform': 'scaleX(0)'}),
    }),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.debt-card__fill').styles(
        raw: {'animation': 'none', 'transition': 'none'},
      ),
    ]),
    css('.debt-card__due').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-xs)',
        'margin': '0',
      },
    ),
    css('.debt-card__due .birka-icon').styles(
      raw: {'flex': 'none', 'height': '16px', 'width': '16px'},
    ),
  ];
}

class _DebtPageState extends State<DebtPage> {
  late bool _returnOpen = component.returnOpen;

  void _close() => setState(() => _returnOpen = false);

  @override
  Component build(BuildContext context) {
    return BlocConsumer<DebtsCubit, DebtsState>(
      listenWhen: (before, now) =>
          before.debt(component.id) != null && now.debt(component.id) == null,
      listener: (_, _) => component.onBack(),
      builder: (context, state) {
        final debt = state.debt(component.id);
        return BirkaColumn(
          children: [
            BackHeader(
              label: t.debts.card.title,
              backLabel: component.closes ? t.debts.close : t.debts.title,
              onBack: component.onBack,
              closes: component.closes,
              trailing: debt == null
                  ? null
                  : BirkaChip(
                      label: t.debts.card.edit,
                      selected: false,
                      href: component.editHref,
                    ),
            ),
            if (state.status == DebtsStatus.failed)
              GlassNotice(text: t.debts.failed),
            if (state.status == DebtsStatus.ready && debt == null)
              GlassNotice(text: t.debts.gone),
            if (debt != null) ..._card(debt, state.today),
          ],
        );
      },
    );
  }

  List<Component> _card(Debt debt, CivilDate today) {
    final lent = debt.side == DebtSide.lent;
    final returnForm = component.returnForm;
    return [
      _summary(debt, today),
      _settled(debt, today),
      div(classes: 'glass-action-tiles', [
        GlassActionTile(
          glyph: lent ? BirkaGlyph.download : BirkaGlyph.upload,
          label: lent ? t.debts.card.returnAction : t.debts.card.repayAction,
          accent: !debt.closed,
          expanded: _returnOpen && !debt.closed,
          onTap: debt.closed
              ? null
              : () => setState(() => _returnOpen = !_returnOpen),
        ),
        GlassActionTile(
          glyph: BirkaGlyph.plus,
          label: debt.closed
              ? t.debts.card.newDebt
              : lent
              ? t.debts.card.lendMore
              : t.debts.card.borrowMore,
          href: component.moreHref,
        ),
      ]),
      if (returnForm != null)
        BirkaFold(
          open: _returnOpen && !debt.closed,
          children: [if (_returnOpen && !debt.closed) returnForm(_close)],
        ),
      section(classes: 'debts__group', [
        SectionLabel(t.debts.card.history),
        GlassListGroup(
          children: [
            for (final step in debt.steps)
              GlassListRow(
                key: ValueKey(step.transactionId),
                leading: GlyphBadge(
                  glyph: step.onAccount.isPositive
                      ? BirkaGlyph.download
                      : BirkaGlyph.upload,
                  color: step.move.settles
                      ? 'var(--color-accent)'
                      : 'var(--color-text-secondary)',
                ),
                title: debtStepTitle(step),
                subtitle: debtStepLine(step, today: today),
                subtitleLines: 2,
                trailing: AmountText(
                  debtStepAmount(step),
                  tone: step.move.settles
                      ? AmountTone.positive
                      : AmountTone.neutral,
                  textClass: 'text-body-strong',
                ),
                href: component.hrefOfOperation(step.transactionId),
              ),
          ],
        ),
      ]),
    ];
  }

  /// The person, what is left and of what.
  Component _summary(Debt debt, CivilDate today) {
    return div(classes: 'debt-card__summary', [
      span(classes: 'debt-card__badge', [
        DebtBadge(debt.account, size: 72),
        if (debt.closed)
          const span(classes: 'debt-card__check', [
            BirkaIcon(BirkaGlyph.check),
          ]),
      ]),
      h1(classes: 'text-heading debt-card__name', [.text(debt.name)]),
      AmountText(debtAmount(debt.left), textClass: 'text-display'),
      p(classes: 'text-body debt-card__line', [
        .text(debtLeftLine(debt, today: today)),
      ]),
    ]);
  }

  /// What came back, as a bar, and the day of the debt. The site has no
  /// reminders, so the day says nothing of them.
  Component _settled(Debt debt, CivilDate today) {
    final due = debtDueLine(debt, today: today, reminders: false);
    final share = (debt.share * 100).toStringAsFixed(1);
    return GlassSurface(
      child: div(classes: 'debt-card__settled', [
        div(classes: 'debt-card__settled-head', [
          AmountText(debtSettledTitle(debt), textClass: 'text-body-strong'),
          span(classes: 'text-caption debt-card__share', [
            .text(debtShare(debt)),
          ]),
        ]),
        span(
          classes: 'debt-card__bar',
          attributes: const {'aria-hidden': 'true'},
          [
            span(
              classes: 'debt-card__fill',
              styles: Styles(raw: {'width': '$share%'}),
              const [],
            ),
          ],
        ),
        p(
          classes: 'text-body debt-card__due',
          styles: Styles(raw: {'color': debtToneColor(due.tone)}),
          [
            const BirkaIcon(BirkaGlyph.calendar),
            span([.text(due.text)]),
          ],
        ),
      ]),
    );
  }
}
