import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';

/// What stands beside the operations of a question on a wide page, in
/// place of the card of the month (ADR 0028): the question, what the list
/// shows, and the way back to the answer.
class OperationsFocusCard extends StatelessComponent {
  /// Creates the card of [question].
  const OperationsFocusCard({
    required this.question,
    required this.answerHref,
    super.key,
  });

  /// The question, as it was asked.
  final String question;

  /// Where the answer opens again.
  final String answerHref;

  @override
  Component build(BuildContext context) {
    return section(classes: 'glass operations-focus', [
      SectionLabel(t.transactions.fromQuestion),
      p(classes: 'text-heading operations-focus__question', [
        .text('«$question»'),
      ]),
      p(classes: 'text-body operations-focus__text', [
        .text(t.transactions.focusText),
      ]),
      BirkaButton(
        label: t.transactions.backToAnswer,
        quiet: true,
        href: answerHref,
      ),
    ]);
  }

  /// The styles of the card.
  @css
  static List<StyleRule> get styles => [
    css('.glass.operations-focus').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.operations-focus__question').styles(
      raw: {'margin': '0', 'overflow-wrap': 'anywhere'},
    ),
    css('.operations-focus__text').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css('.operations-focus .birka-button').styles(
      raw: {'margin-top': 'var(--space-xs)'},
    ),
  ];
}
