import 'dart:async';

import 'package:debts_common/debts_common.dart';
import 'package:debts_jaspr/src/presentation/components/debt_badge.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// The card of a debt (ADR 0029): the person and who they are, what is left
/// of what, the bar of what came back, its day, the return in a fold under
/// the actions, more money, a reminder whose text the person copies
/// (ADR 0030), and its steps. Beside the list on a wide page it [closes]
/// with a cross.
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
    this.onCopy,
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

  /// Copies the text of a reminder for the person to send, where the host
  /// can. Without it a debt has no reminder.
  final Future<void> Function(String text)? onCopy;

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
    css('.debt-card__who').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': '2px',
      },
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
    css('.debt-remind').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
      },
    ),
    css('.debt-remind__to').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-secondary)',
        'display': 'flex',
        'gap': 'var(--space-xs)',
        'margin': '0',
      },
    ),
    css('.debt-remind__to .birka-icon').styles(
      raw: {'flex': 'none', 'height': '18px', 'width': '18px'},
    ),
    // The number is picked whole with one click, to copy it.
    css('.debt-remind__number').styles(
      raw: {'color': 'var(--color-text)', 'user-select': 'all'},
    ),
    css('.debt-remind__note').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
  ];
}

/// What opens under the actions of a card, one at a time.
enum _Fold { back, remind }

class _DebtPageState extends State<DebtPage> {
  late _Fold? _open = component.returnOpen ? _Fold.back : null;

  void _close() => setState(() => _open = null);

  /// Opens [fold], closing the other one, or closes it when it is open.
  void _toggle(_Fold fold) =>
      setState(() => _open = _open == fold ? null : fold);

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
            if (debt != null) ..._card(debt, state),
          ],
        );
      },
    );
  }

  List<Component> _card(Debt debt, DebtsState state) {
    final today = state.today;
    final lent = debt.side == DebtSide.lent;
    final returnForm = component.returnForm;
    final onCopy = component.onCopy;
    final back = _open == _Fold.back && !debt.closed;
    // Money owed to the person can be reminded of with a text to send.
    final reminds = lent && !debt.closed && onCopy != null;
    final remind = _open == _Fold.remind && reminds;
    return [
      _summary(debt, state.personOf(debt)?.about.trim() ?? '', today),
      _settled(debt, today),
      div(classes: 'glass-action-tiles', [
        GlassActionTile(
          glyph: lent ? BirkaGlyph.download : BirkaGlyph.upload,
          label: lent ? t.debts.card.returnAction : t.debts.card.repayAction,
          accent: !debt.closed,
          expanded: back,
          onTap: debt.closed ? null : () => _toggle(_Fold.back),
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
        if (reminds)
          GlassActionTile(
            glyph: BirkaGlyph.message,
            label: t.debts.remind.action,
            expanded: remind,
            onTap: () => _toggle(_Fold.remind),
          ),
      ]),
      if (returnForm != null)
        BirkaFold(open: back, children: [if (back) returnForm(_close)]),
      if (onCopy != null)
        BirkaFold(
          open: remind,
          children: [
            if (remind)
              _Remind(
                debt: debt,
                person: state.personOf(debt),
                today: today,
                onCopy: onCopy,
              ),
          ],
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

  /// The person and who they are, what is left and of what.
  Component _summary(Debt debt, String about, CivilDate today) {
    return div(classes: 'debt-card__summary', [
      span(classes: 'debt-card__badge', [
        DebtBadge(debt.account, size: 72),
        if (debt.closed)
          const span(classes: 'debt-card__check', [
            BirkaIcon(BirkaGlyph.check),
          ]),
      ]),
      div(classes: 'debt-card__who', [
        h1(classes: 'text-heading debt-card__name', [.text(debt.name)]),
        if (about.isNotEmpty)
          p(classes: 'text-body debt-card__line', [.text(about)]),
      ]),
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

/// The reminder of [debt] in the fold under the actions (ADR 0030): a ready
/// text that the person may change and copy, and the number to send it to.
/// The site sends nothing itself.
class _Remind extends StatefulComponent {
  const _Remind({
    required this.debt,
    required this.person,
    required this.today,
    required this.onCopy,
  });

  final Debt debt;
  final Person? person;
  final CivilDate today;
  final Future<void> Function(String text) onCopy;

  /// The ready text of the reminder.
  String get text => debtRemindText(debt, today: today);

  @override
  State<_Remind> createState() => _RemindState();
}

class _RemindState extends State<_Remind> {
  /// What the person typed, once they did.
  String? _typed;

  @override
  void didUpdateComponent(_Remind oldComponent) {
    super.didUpdateComponent(oldComponent);
    // A new text, as after a return, starts over.
    if (oldComponent.text != component.text) _typed = null;
  }

  @override
  Component build(BuildContext context) {
    final words = t.debts.remind;
    final text = component.text;
    final number = component.person?.phone;
    return GlassSurface(
      child: div(classes: 'debt-remind', [
        BirkaTextField(
          key: ValueKey(text),
          label: words.message,
          value: text,
          lines: 3,
          sentence: true,
          onChanged: (typed) => _typed = typed,
        ),
        p(classes: 'text-body debt-remind__to', [
          const BirkaIcon(BirkaGlyph.contact),
          span([
            .text('${component.debt.name} · '),
            if (number != null)
              span(classes: 'debt-remind__number', [.text(number)])
            else
              .text(words.noPhone),
          ]),
        ]),
        p(classes: 'text-caption debt-remind__note', [
          .text(words.captionSite),
        ]),
        BirkaButton(
          label: words.copy,
          onPressed: () => unawaited(component.onCopy((_typed ?? text).trim())),
        ),
      ]),
    );
  }
}
