import 'package:design_jaspr/design_jaspr.dart';
import 'package:import_common/import_common.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';

/// [amount] with its sign: «+185 000 ₽» or «−2 340,50 ₽».
String signedMoney(Money amount) =>
    amount.isPositive ? '+${formatMoney(amount)}' : formatMoney(amount);

/// The sums of [amounts] in each of their currencies, on one line:
/// «−148 230,40 ₽ · −12 $», or a dash for none.
String moneyLine(Iterable<Money> amounts, {bool signed = false}) {
  final sums = <Currency, Money>{};
  for (final amount in amounts) {
    sums[amount.currency] =
        (sums[amount.currency] ?? Money(0, amount.currency)) + amount;
  }
  if (sums.isEmpty) return '—';
  return [
    for (final sum in sums.values) signed ? signedMoney(sum) : formatMoney(sum),
  ].join(' · ');
}

/// What an operation of the plan does to money, with its sign: an expense
/// takes, an income brings, and a transfer only moves.
Money signedAmount(PlannedOperation operation) => switch (operation.kind) {
  TransactionKind.expense => -operation.amount,
  _ => operation.amount,
};

/// The tone of [amount] for people: money in is green, money out is plain.
AmountTone toneOf(Money amount) =>
    amount.isPositive ? AmountTone.positive : AmountTone.neutral;

/// A day of the ledger for people, with its year when it is not this one.
String dayLabel(CivilDate day, {required int thisYear}) => dateLabel(
  year: day.year,
  month: day.month,
  day: day.day,
  thisYear: thisYear,
);

/// The mark of a format: the first letter of its bank in its color, or a
/// plus for a format of one's own.
class FormatMark extends StatelessComponent {
  /// Creates the mark of [format].
  const FormatMark(this.format, {super.key});

  /// The format, or `null` for one of one's own.
  final StatementFormat? format;

  /// The color of [format].
  static String colorOf(StatementFormat? format) => switch (format?.id) {
    'alfa' => 'var(--color-palette-ruby)',
    'tbank' => 'var(--color-palette-amber)',
    'sber' => 'var(--color-palette-green)',
    'zenmoney' => 'var(--color-palette-emerald400)',
    'wise' => 'var(--color-palette-sky)',
    'revolut' => 'var(--color-palette-violet)',
    _ => 'var(--color-text-muted)',
  };

  @override
  Component build(BuildContext context) {
    final format = this.format;
    final color = colorOf(format);
    return span(
      classes: 'text-body-strong import-mark',
      styles: Styles(
        raw: {
          'background': 'color-mix(in srgb, $color 18%, transparent)',
          'color': color,
        },
      ),
      attributes: const {'aria-hidden': 'true'},
      [
        if (format == null || isOwnFormat(format))
          const BirkaIcon(BirkaGlyph.plus)
        else
          .text(formatLabel(format).substring(0, 1)),
      ],
    );
  }

  /// The styles of the mark.
  @css
  static List<StyleRule> get styles => [
    css('.import-mark').styles(
      raw: {
        'align-items': 'center',
        'border-radius': 'var(--radius-sm)',
        'display': 'flex',
        'flex': 'none',
        'height': '36px',
        'justify-content': 'center',
        'width': '36px',
      },
    ),
    css('.import-mark .birka-icon').styles(
      raw: {'height': '16px', 'width': '16px'},
    ),
  ];
}

/// The file of the import as a card: its mark, its name and its format.
class FileCard extends StatelessComponent {
  /// Creates the card of the file of [state].
  const FileCard(this.state, {this.into, super.key});

  /// The import.
  final ImportState state;

  /// Where its operations go, once that is chosen.
  final String? into;

  @override
  Component build(BuildContext context) {
    final format = state.layout?.format;
    final table = state.table;
    final kind = table == null ? null : t.imports.fileKinds[table.file.name];
    final what = format == null ? t.imports.own : formatLabel(format);
    final into = this.into;
    return div(classes: 'import-file', [
      FormatMark(format),
      div(classes: 'import-file__text', [
        span(classes: 'text-body-strong import-file__name', [
          .text(state.fileName ?? ''),
        ]),
        span(classes: 'text-caption import-file__line', [
          .text(
            [
              if (kind == null) what else '$what · $kind',
              ?into,
            ].join(' → '),
          ),
        ]),
      ]),
    ]);
  }

  /// The styles of the card.
  @css
  static List<StyleRule> get styles => [
    css('.import-file').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-surface)',
        'border-radius': 'var(--radius-md)',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'padding': 'var(--space-sm)',
      },
    ),
    css('.import-file__text').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'min-width': '0',
      },
    ),
    css('.import-file__name').styles(
      raw: {
        'color': 'var(--color-text)',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.import-file__line').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
  ];
}

/// A line of a summary: what is counted and how much.
class SummaryRow extends StatelessComponent {
  /// Creates the line.
  const SummaryRow(
    this.label,
    this.value, {
    this.tone,
    this.strong = false,
    super.key,
  });

  /// What is counted.
  final String label;

  /// How much.
  final String value;

  /// The tone of an amount, when [value] is one.
  final AmountTone? tone;

  /// Whether the line is the sum of the others.
  final bool strong;

  @override
  Component build(BuildContext context) {
    final tone = this.tone;
    return div(
      classes: strong ? 'import-row import-row--strong' : 'import-row',
      [
        span(classes: 'text-body import-row__label', [.text(label)]),
        if (tone != null)
          AmountText(value, tone: tone, textClass: 'text-body-strong')
        else
          span(
            classes: strong
                ? 'text-amount import-row__value'
                : 'text-body-strong import-row__value',
            [.text(value)],
          ),
      ],
    );
  }

  /// The styles of the line.
  @css
  static List<StyleRule> get styles => [
    css('.import-row').styles(
      raw: {
        'align-items': 'baseline',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
      },
    ),
    css('.import-row--strong').styles(
      raw: {
        'border-top': '1px solid var(--color-hairline)',
        'padding-top': 'var(--space-sm)',
      },
    ),
    css('.import-row__label').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.import-row__value').styles(
      raw: {'color': 'var(--color-text)', 'text-align': 'end'},
    ),
  ];
}
