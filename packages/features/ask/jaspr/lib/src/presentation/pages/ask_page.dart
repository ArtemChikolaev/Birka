import 'dart:async';

import 'package:ask_common/ask_common.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// Builds the card of a fact that another feature keeps, such as what can be
/// spent today, or gives `null` to lead to its page.
typedef AskFactBuilder = Component? Function(AskFact fact);

/// «Спросить» on the site (ADR 0028): a field that takes a question about
/// money in words, the examples and the questions asked last, and the answer:
/// plaques of what the question was read as and what the ledger says, a
/// fact, the help, the pages, or a fixed reply.
///
/// A [wide] page keeps the examples beside the answer; a narrow one shows
/// them until there is a question. A question is read once the fingers
/// pause, and an example or a question asked last is asked at once.
///
/// It needs an [AskCubit] above it.
class AskPage extends StatefulComponent {
  /// Creates the page.
  const AskPage({
    required this.onQuestion,
    required this.operationsHref,
    required this.onShowOperations,
    required this.hrefOfOperation,
    required this.hrefOfTag,
    required this.hrefOfPlace,
    required this.helpHref,
    this.question = '',
    this.fact,
    this.wide = false,
    super.key,
  });

  /// The question the page opens with, such as the one of its address. A new
  /// one, as the address changes, is asked at once.
  final String question;

  /// Called with the question each time it is asked, so that the address
  /// can keep it.
  final ValueChanged<String> onQuestion;

  /// Where the operations of an answer open.
  final String operationsHref;

  /// Called as «Показать N операций» leads to [operationsHref], with the
  /// answer, its title and the question, which that page shows alone.
  final void Function(AskAnswer answer, String title, String question)
  onShowOperations;

  /// Where the operation with this id opens.
  final String Function(String id) hrefOfOperation;

  /// Where the report of the метка with this id opens.
  final String Function(String id) hrefOfTag;

  /// Where a page that an answer names opens, or `null` when the site has
  /// no such page.
  final String? Function(AskPlace place) hrefOfPlace;

  /// Where the help opens, where the person can also write to the developer.
  final String helpHref;

  /// The card of a fact that another feature keeps.
  final AskFactBuilder? fact;

  /// Whether the page is wide.
  final bool wide;

  @override
  State<AskPage> createState() => _AskPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.ask__group').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.ask__group > .section-label').styles(
      raw: {'padding': '0 var(--space-xs)'},
    ),
    css('.ask__heading').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'justify-content': 'space-between',
        'padding': '0 var(--space-xs)',
      },
    ),
    css('.ask__forget').styles(
      raw: {
        'background': 'none',
        'border': '0',
        'color': 'var(--color-accent)',
        'cursor': 'pointer',
        'padding': 'var(--space-xxs) 0',
      },
    ),
    css('.ask__muted').styles(
      raw: {'color': 'var(--color-text-muted)', 'display': 'flex'},
    ),
    css('.ask__muted .birka-icon').styles(
      raw: {'height': '20px', 'width': '20px'},
    ),
    css('.ask__caption').styles(
      raw: {'color': 'var(--color-text-subtle)', 'margin': '0'},
    ),
    css('.ask__key').styles(
      raw: {
        'background': 'var(--color-surface-raised)',
        'border-radius': 'var(--radius-xs)',
        'color': 'var(--color-text)',
        'display': 'inline-block',
        'padding': '0 var(--space-xs)',
      },
    ),
    css('.glass.ask__card').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.ask__card > .section-label').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.ask__title').styles(raw: {'margin': '0'}),
    css('.ask__line').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css('.ask__figure').styles(
      raw: {
        'align-items': 'baseline',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.ask__figure .amount').styles(
      raw: {'overflow-wrap': 'anywhere', 'white-space': 'normal'},
    ),
    css('.ask__change').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.ask__card .birka-bars').styles(
      raw: {'margin-top': 'var(--space-xs)'},
    ),
    css('.ask__card .birka-button').styles(
      raw: {'margin-top': 'var(--space-xs)'},
    ),
    css('.ask__chips').styles(
      raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': 'var(--space-xs)'},
    ),
    css('.glass.ask__periods').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.ask__amounts').styles(
      raw: {
        'align-items': 'flex-end',
        'display': 'flex',
        'flex-direction': 'column',
      },
    ),
    css('.glass.ask__reply').styles(
      raw: {
        'align-items': 'flex-start',
        'display': 'flex',
        'gap': 'var(--space-md)',
      },
    ),
    css('.ask__reply-text').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
      },
    ),
    css('.ask__help').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'padding': 'var(--space-md) var(--space-md) var(--space-xs)',
      },
    ),
    css('.ask__help p').styles(raw: {'margin': '0'}),
    css('.ask__answered').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    // An answer to another question rises into place, part after part.
    css('.ask__answer').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
      },
    ),
    css('.ask__answer > *').styles(
      raw: {
        'animation':
            'ask-part-in var(--duration-slow) var(--easing-standard) both',
      },
    ),
    for (var i = 2; i <= 6; i++)
      css('.ask__answer > *:nth-child($i)').styles(
        raw: {'animation-delay': '${(i - 1) * 60}ms'},
      ),
    css.keyframes('ask-part-in', {
      'from': const Styles(
        raw: {'opacity': '0', 'transform': 'translateY(var(--space-xs))'},
      ),
      'to': const Styles(raw: {'opacity': '1', 'transform': 'none'}),
    }),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.ask__answer > *').styles(
        raw: {'animation': 'ask-part-fade var(--duration-base) both'},
      ),
      css.keyframes('ask-part-fade', {
        'from': const Styles(raw: {'opacity': '0'}),
        'to': const Styles(raw: {'opacity': '1'}),
      }),
    ]),
  ];
}

class _AskPageState extends State<AskPage> {
  /// The question as it stands in the field.
  late String _text = component.question;

  /// Whether the periods to count over are open under the plaques.
  var _choosingPeriod = false;

  Timer? _wait;

  AskCubit get _cubit => context.read<AskCubit>();

  @override
  void didUpdateComponent(AskPage oldComponent) {
    super.didUpdateComponent(oldComponent);
    final question = component.question;
    if (question == oldComponent.question || question == _text.trim()) return;
    _wait?.cancel();
    _text = question;
    _choosingPeriod = false;
    _cubit.ask(question);
  }

  @override
  void dispose() {
    _wait?.cancel();
    super.dispose();
  }

  /// A question being typed is read once the fingers pause.
  void _changed(String text) {
    _wait?.cancel();
    setState(() {
      _text = text;
      _choosingPeriod = false;
    });
    if (text.trim().isEmpty) return _read('');
    _wait = Timer(const Duration(milliseconds: 380), () {
      if (mounted) _read(text);
    });
  }

  void _read(String text) {
    _cubit.ask(text);
    component.onQuestion(text.trim());
  }

  /// Enter asks at once and keeps the question among those asked last.
  void _submitted() {
    _wait?.cancel();
    _read(_text);
    unawaited(_cubit.remember());
  }

  /// Asks [question] at once, as an example or a question asked last does.
  void _ask(String question) {
    _wait?.cancel();
    setState(() {
      _text = question;
      _choosingPeriod = false;
    });
    _read(question);
    unawaited(_cubit.remember());
  }

  /// Keeps the question among those asked last as a link leads away.
  void _leaving() => unawaited(_cubit.remember());

  @override
  Component build(BuildContext context) {
    return BlocBuilder<AskCubit, AskState>(
      builder: (context, state) {
        final field = GlassSearchField(
          label: t.ask.title,
          clearLabel: t.ask.clear,
          hint: t.ask.hint,
          value: _text,
          autofocus: true,
          onChanged: _changed,
          onSubmitted: _submitted,
        );
        final reading = state.reading;
        final header = GlassPageHeader(title: t.ask.title);
        if (component.wide) {
          return BirkaColumn(
            children: [
              header,
              BirkaSplit(
                asideWidth: 400,
                main: [
                  field,
                  if (reading == null) ..._welcome() else _answer(state),
                ],
                aside: [
                  ..._start(state),
                  p(classes: 'text-caption ask__caption', [
                    .text(t.ask.slash),
                  ]),
                ],
              ),
            ],
          );
        }
        return BirkaColumn(
          children: [
            header,
            field,
            if (reading == null) ...[
              ..._start(state),
              p(classes: 'text-caption ask__caption', [
                .text(t.ask.privateWeb),
              ]),
            ] else
              _answer(state),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------- start

  /// What the main side of a wide page says before a question.
  List<Component> _welcome() => [
    div(classes: 'glass ask__card', [
      h2(classes: 'text-heading ask__title', [.text(t.ask.start.title)]),
      p(classes: 'text-body ask__line', [.text(t.ask.start.text)]),
    ]),
    p(classes: 'text-caption ask__caption', [.text(t.ask.privateWeb)]),
  ];

  /// The examples and the questions asked last. The examples wait for the
  /// categories and the метки, so that they do not shuffle.
  List<Component> _start(AskState state) {
    if (!state.ready) return const [];
    return [
      section(classes: 'ask__group', [
        SectionLabel(t.ask.examples),
        GlassListGroup(
          children: [
            for (final example in state.examples)
              GlassListRow(
                key: ValueKey(example.kind),
                leading: _exampleBadge(example),
                title: example.question,
                subtitle: example.line,
                chevron: true,
                onTap: () => _ask(example.question),
              ),
          ],
        ),
      ]),
      BirkaFold(
        open: state.recent.isNotEmpty,
        children: [
          section(classes: 'ask__group', [
            div(classes: 'ask__heading', [
              SectionLabel(t.ask.recent),
              button(
                classes: 'text-body-strong ask__forget',
                type: ButtonType.button,
                onClick: () => unawaited(_cubit.forget()),
                [.text(t.ask.forget)],
              ),
            ]),
            GlassListGroup(
              children: [
                for (final question in state.recent)
                  GlassListRow(
                    key: ValueKey(question),
                    leading: const span(classes: 'ask__muted', [
                      BirkaIcon(BirkaGlyph.search),
                    ]),
                    title: question,
                    onTap: () => _ask(question),
                  ),
              ],
            ),
          ]),
        ],
      ),
    ];
  }

  static Component _exampleBadge(AskExample example) {
    final category = example.category;
    final (glyph, color) = switch (example.kind) {
      AskExampleKind.category => (
        BirkaGlyph.named(category?.icon),
        category?.color ?? 'var(--color-accent)',
      ),
      AskExampleKind.trip => (BirkaGlyph.plane, 'var(--color-accent)'),
      AskExampleKind.big => (BirkaGlyph.rise, 'var(--color-negative)'),
      AskExampleKind.allowance => (BirkaGlyph.wallet, 'var(--color-accent)'),
      AskExampleKind.payments => (BirkaGlyph.repeat, 'var(--color-accent)'),
      AskExampleKind.help => (BirkaGlyph.book, 'var(--color-text-secondary)'),
    };
    return GlyphBadge(glyph: glyph, color: color);
  }

  // ---------------------------------------------------------------- answers

  /// The answer, which rises in anew for another question and stays in
  /// place when only its period changes.
  Component _answer(AskState state) {
    final reading = state.reading!;
    return div(
      key: ValueKey(_topic(reading)),
      classes: 'ask__answer',
      switch (reading) {
        AskData() => _data(state, reading),
        AskFactReading(:final fact) => _fact(state, fact),
        AskHelpReading(:final questions, :final places) => [
          _help(questions),
          ?_places(places),
        ],
        AskPlacesReading(:final places) => [?_places(places)],
        AskRefused(:final reason) => _refused(state, reason),
        AskUnknown() => _unknown(state),
      },
    );
  }

  /// What a reading is about, without its period.
  static String _topic(AskReading reading) => switch (reading) {
    AskData(:final query) => [
      'data',
      query.side.name,
      ...query.categoryIds,
      ?query.tagId,
      ?query.accountId,
      ...query.words,
      ?query.above?.toString(),
      ?query.below?.toString(),
    ].join(' '),
    _ => reading.toJson().toString(),
  };

  List<Component> _data(AskState state, AskData reading) {
    final query = reading.query;
    final answer = state.answer;
    final title = answerTitle(query, state.names, today: state.today);
    final trip = switch (state.names.tags[query.tagId]) {
      final tag? when tag.isTrip => tag,
      _ => null,
    };
    return [
      _chips(state, query.period),
      if (answer != null) ...[
        _answerCard(state, answer, title),
        ?_operations(state, answer),
        ?_shares(answer),
        if (trip != null)
          _link(
            title: t.ask.answer.trip,
            subtitle: t.ask.answer.tripText,
            glyph: BirkaGlyph.plane,
            href: component.hrefOfTag(trip.id),
          ),
        ?_places(reading.places),
        p(classes: 'text-caption ask__caption', [
          .text(
            answer.partial ? t.ask.answer.partial : t.ask.answer.countedWeb,
          ),
        ]),
      ],
    ];
  }

  /// The plaques of what the question was read as. The plaque of the days
  /// opens the periods under them.
  Component _chips(AskState state, AskPeriod? period) {
    return section(classes: 'ask__group', [
      SectionLabel(t.ask.understood),
      div(classes: 'ask__chips', [
        for (final chip in state.chips)
          if (chip.kind == AskChipKind.period && period != null)
            BirkaChip(
              key: ValueKey(chip.kind),
              label: chip.label,
              selected: true,
              glyph: BirkaGlyph.calendar,
              trailingGlyph: BirkaGlyph.chevron,
              trailingTurns: _choosingPeriod ? 3 : 1,
              expanded: _choosingPeriod,
              onTap: () => setState(() => _choosingPeriod = !_choosingPeriod),
            )
          else
            BirkaChip(
              key: ValueKey(chip.kind),
              label: chip.label,
              selected: true,
              glyph: switch (chip.kind) {
                AskChipKind.category => BirkaGlyph.named(chip.category?.icon),
                AskChipKind.tag =>
                  chip.tag?.isTrip ?? false ? BirkaGlyph.plane : BirkaGlyph.tag,
                AskChipKind.account => BirkaGlyph.wallet,
                AskChipKind.period => BirkaGlyph.calendar,
                _ => null,
              },
            ),
      ]),
      if (period != null)
        BirkaFold(
          open: _choosingPeriod,
          gap: 'var(--space-xs)',
          children: [
            div(classes: 'glass ask__periods', [
              SectionLabel(t.ask.period.title),
              div(classes: 'ask__chips', [
                for (final choice in state.periods)
                  BirkaChip(
                    key: ValueKey(choice.first),
                    label: periodLabel(choice, today: state.today),
                    selected: choice == period,
                    compact: true,
                    onTap: () {
                      setState(() => _choosingPeriod = false);
                      _cubit.choosePeriod(choice);
                    },
                  ),
              ]),
            ]),
          ],
        ),
    ]);
  }

  /// What the ledger says: the title, the total, the count and the mean,
  /// the change against the stretch before, the bars and the way to the
  /// operations.
  Component _answerCard(AskState state, AskAnswer answer, String title) {
    final income = answer.query.side == AskSide.income;
    final period = answer.query.period;
    final before = answer.before;
    final change = before == null ? null : answer.total - before;
    return section(classes: 'glass ask__card', [
      SectionLabel(title),
      div(classes: 'ask__figure', [
        AmountText(
          income ? signedMoney(answer.total) : formatMoney(answer.total),
          tone: income ? AmountTone.positive : AmountTone.neutral,
          textClass: 'text-display',
        ),
      ]),
      p(classes: 'text-body ask__line', [
        .text(answer.count == 0 ? t.ask.answer.none : answerLine(answer)),
      ]),
      if (change != null && period != null && !change.isZero)
        div(classes: 'ask__change', [
          BirkaChangePill(
            label: signedMoney(change),
            rise: change.isPositive,
            good: income ? change.isPositive : change.isNegative,
          ),
          span(classes: 'text-body ask__line', [
            .text(beforeLabel(period, today: state.today)),
          ]),
        ]),
      if (answer.bars.isNotEmpty)
        BirkaBars(
          bars: [
            for (final bar in answer.bars)
              BirkaBar(
                value: bar.total.minorUnits.toDouble(),
                amount: formatCompactFigure(bar.total),
                label: barLabel(bar),
                highlighted: bar.top,
              ),
          ],
        ),
      if (answer.count == 0)
        p(classes: 'text-caption ask__caption', [
          .text(t.ask.answer.noneText),
        ])
      else
        BirkaButton(
          label: t.ask.answer.show(n: answer.count),
          quiet: true,
          href: component.operationsHref,
          onPressed: () {
            _leaving();
            component.onShowOperations(answer, title, _text.trim());
          },
        ),
    ]);
  }

  /// The biggest operations, or all of them for a question with a bound or
  /// words, which leads to every one.
  Component? _operations(AskState state, AskAnswer answer) {
    final query = answer.query;
    final all =
        query.above != null || query.below != null || query.words.isNotEmpty;
    final shown = all ? answer.operations.take(20) : answer.biggest;
    if (shown.isEmpty) return null;
    return section(classes: 'ask__group', [
      SectionLabel(all ? t.ask.answer.operationsTitle : t.ask.answer.biggest),
      GlassListGroup(
        children: [
          for (final operation in shown) _operationRow(state, operation),
        ],
      ),
    ]);
  }

  Component _operationRow(AskState state, AskOperation operation) {
    final transaction = operation.transaction;
    final allocation = transaction.allocations.firstOrNull;
    final category = state.names.categories[allocation?.categoryId];
    final account = state.names.accounts[transaction.entries.first.accountId];
    final day = transaction.occurredOn;
    final income = transaction.kind == TransactionKind.income;
    final amount = income ? operation.amount : -operation.amount;
    final counted = operation.counted;
    return GlassListRow(
      key: ValueKey(transaction.id),
      leading: GlyphBadge(
        glyph: BirkaGlyph.named(category?.icon),
        color: category?.color ?? 'var(--color-text-muted)',
        size: 40,
      ),
      title: transaction.note.isEmpty
          ? category?.name ?? t.ask.answer.noCategory
          : transaction.note,
      subtitle: [
        dateLabel(
          year: day.year,
          month: day.month,
          day: day.day,
          thisYear: state.today.year,
        ),
        ?account?.name,
      ].join(' · '),
      trailing: span(classes: 'ask__amounts', [
        AmountText(
          signedMoney(amount),
          tone: income ? AmountTone.positive : AmountTone.neutral,
          textClass: 'text-body-strong',
        ),
        if (counted != null && counted.currency != operation.amount.currency)
          AmountText(
            '≈ ${formatMoney(counted)}',
            tone: AmountTone.muted,
            textClass: 'text-caption',
          ),
      ]),
      href: component.hrefOfOperation(transaction.id),
      onTap: _leaving,
    );
  }

  /// The shares of the categories, when there are two or more.
  Component? _shares(AskAnswer answer) {
    final shares = answer.shares;
    if (shares.length < 2) return null;
    final top = shares.first.total.minorUnits;
    return section(classes: 'ask__group', [
      SectionLabel(
        answer.query.side == AskSide.income
            ? t.ask.answer.sharesIncome
            : t.ask.answer.sharesExpenses,
      ),
      GlassListGroup(
        children: [
          for (final share in shares)
            ShareLine(
              key: ValueKey(share.category?.id),
              color: share.category?.color ?? 'var(--color-text-subtle)',
              title: share.category?.name ?? t.ask.answer.noCategory,
              note: span(classes: 'text-caption ask__line', [
                .text('${share.percent}%'),
              ]),
              amount: AmountText(
                formatMoney(share.total),
                textClass: 'text-body-strong',
              ),
              fraction: top == 0 ? 0 : share.total.minorUnits / top,
            ),
        ],
      ),
    ]);
  }

  List<Component> _fact(AskState state, AskFact fact) => switch (fact) {
    AskFact.allowance || AskFact.payments => [
      ?component.fact?.call(fact),
      ?_places([
        if (fact == AskFact.allowance) AskPlace.payday else AskPlace.schedules,
      ]),
    ],
    AskFact.capital => _capital(state),
    AskFact.rate => _rate(state),
  };

  List<Component> _capital(AskState state) {
    final capital = state.capital;
    final main = capital?.main;
    final accounts = [
      for (final balance in state.balances)
        if (balance.account.includeInTotals && !balance.account.archived)
          balance,
    ];
    return [
      section(classes: 'glass ask__card', [
        SectionLabel(
          t.ask.fact.capital(
            currencies: t.overview.currencies(n: capital?.currencies ?? 0),
          ),
        ),
        div(classes: 'ask__figure', [
          AmountText(
            main == null ? '—' : formatMoney(main),
            textClass: 'text-display',
          ),
        ]),
        p(classes: 'text-body ask__line', [
          .text(t.ask.fact.accounts(n: accounts.length)),
        ]),
      ]),
      if (accounts.isNotEmpty)
        GlassListGroup(
          children: [
            for (final balance in accounts)
              GlassListRow(
                key: ValueKey(balance.account.id),
                title: balance.account.name,
                trailing: AmountText(
                  formatMoney(balance.balance),
                  textClass: 'text-body-strong',
                ),
              ),
          ],
        ),
      ?_placeLink(
        AskPlace.accounts,
        title: t.ask.fact.allAccounts,
        subtitle: t.ask.fact.allAccountsText,
        glyph: BirkaGlyph.wallet,
      ),
    ];
  }

  List<Component> _rate(AskState state) {
    final reading = state.reading;
    final currency = reading is AskFactReading ? reading.currency : null;
    final rate = state.rate;
    final day = state.rates.latestDay;
    return [
      section(classes: 'glass ask__card', [
        SectionLabel(
          day == null
              ? t.ask.title
              : t.ask.fact.rate(
                  day: dateLabel(
                    year: day.year,
                    month: day.month,
                    day: day.day,
                    thisYear: state.today.year,
                  ),
                ),
        ),
        if (rate == null || currency == null)
          p(classes: 'text-body ask__line', [.text(t.ask.fact.rateMissing)])
        else ...[
          div(classes: 'ask__figure', [
            AmountText(
              formatMoney(rate),
              alwaysShown: true,
              textClass: 'text-display',
            ),
            span(classes: 'text-body ask__line', [
              .text(t.ask.fact.rateFor(sign: currencySign(currency))),
            ]),
          ]),
          p(classes: 'text-body ask__line', [.text(t.ask.fact.rateKeptWeb)]),
        ],
      ]),
      _link(
        title: t.ask.fact.rateHelp,
        subtitle: t.ask.fact.rateHelpText,
        glyph: BirkaGlyph.book,
        href: component.helpHref,
      ),
    ];
  }

  Component _help(List<int> questions) {
    final all = helpQuestions();
    return section(classes: 'ask__group', [
      SectionLabel(t.ask.help.title),
      GlassListGroup(
        children: [
          for (final index in questions)
            if (index < all.length)
              div(classes: 'ask__help', [
                p(classes: 'text-body-strong', [.text(all[index].question)]),
                p(classes: 'text-body ask__answered', [
                  .text(all[index].answer),
                ]),
              ]),
          GlassListRow(
            title: t.ask.help.all,
            href: component.helpHref,
            chevron: true,
            onTap: _leaving,
          ),
        ],
      ),
    ]);
  }

  /// The pages that a reading names, those the site has.
  Component? _places(List<AskPlace> places) {
    final rows = [
      for (final place in places)
        if (component.hrefOfPlace(place) case final href?)
          GlassListRow(
            key: ValueKey(place),
            leading: GlyphBadge(
              glyph: _glyphOf(place),
              color: 'var(--color-accent)',
            ),
            title: _titleOf(place),
            subtitle: _lineOf(place),
            href: href,
            chevron: true,
            onTap: _leaving,
          ),
    ];
    if (rows.isEmpty) return null;
    return section(classes: 'ask__group', [
      SectionLabel(t.ask.places.title),
      GlassListGroup(children: rows),
    ]);
  }

  /// A row that leads to [place], when the site has it.
  Component? _placeLink(
    AskPlace place, {
    required String title,
    required String subtitle,
    required BirkaGlyph glyph,
  }) {
    final href = component.hrefOfPlace(place);
    if (href == null) return null;
    return _link(title: title, subtitle: subtitle, glyph: glyph, href: href);
  }

  Component _link({
    required String title,
    required String subtitle,
    required BirkaGlyph glyph,
    required String href,
  }) {
    return GlassListGroup(
      children: [
        GlassListRow(
          leading: GlyphBadge(glyph: glyph, color: 'var(--color-accent)'),
          title: title,
          subtitle: subtitle,
          href: href,
          chevron: true,
          onTap: _leaving,
        ),
      ],
    );
  }

  List<Component> _refused(AskState state, AskRefusal reason) {
    final (title, text, suggestions) = switch (reason) {
      AskRefusal.advice => (
        t.ask.refused.advice,
        t.ask.refused.adviceText,
        [t.ask.suggest.rate, t.ask.suggest.capital],
      ),
      AskRefusal.offTopic => (
        t.ask.refused.offTopic,
        t.ask.refused.offTopicText,
        [for (final example in state.examples.take(3)) example.question],
      ),
    };
    return [
      _reply(title: title, text: text, glyph: BirkaGlyph.alert),
      _suggestions(suggestions),
    ];
  }

  List<Component> _unknown(AskState state) => [
    _reply(
      title: t.ask.refused.unknown,
      text: t.ask.refused.unknownText,
      glyph: BirkaGlyph.search,
    ),
    _suggestions([
      for (final example in state.examples.take(3)) example.question,
    ]),
    _link(
      title: t.ask.refused.write,
      subtitle: t.ask.refused.writeText,
      glyph: BirkaGlyph.book,
      href: component.helpHref,
    ),
  ];

  /// A fixed reply: what Birka does not answer, and why.
  static Component _reply({
    required String title,
    required String text,
    required BirkaGlyph glyph,
  }) {
    return section(classes: 'glass ask__reply', [
      GlyphBadge(glyph: glyph, color: 'var(--color-text-secondary)'),
      div(classes: 'ask__reply-text', [
        h2(classes: 'text-heading ask__title', [.text(title)]),
        p(classes: 'text-body ask__line', [.text(text)]),
      ]),
    ]);
  }

  Component _suggestions(List<String> questions) {
    return section(classes: 'ask__group', [
      SectionLabel(t.ask.refused.suggest),
      div(classes: 'ask__chips', [
        for (final question in questions)
          BirkaChip(
            key: ValueKey(question),
            label: question,
            selected: false,
            onTap: () => _ask(question),
          ),
      ]),
    ]);
  }

  static BirkaGlyph _glyphOf(AskPlace place) => switch (place) {
    AskPlace.payday => BirkaGlyph.wallet,
    AskPlace.schedules => BirkaGlyph.repeat,
    AskPlace.tags => BirkaGlyph.tag,
    AskPlace.accounts => BirkaGlyph.wallet,
    AskPlace.categories => BirkaGlyph.list,
    AskPlace.imports => BirkaGlyph.upload,
    AskPlace.inbox => BirkaGlyph.inbox,
    AskPlace.backup => BirkaGlyph.cloud,
    AskPlace.help => BirkaGlyph.book,
    AskPlace.notifications => BirkaGlyph.bell,
    AskPlace.reports => BirkaGlyph.reports,
    AskPlace.settings => BirkaGlyph.more,
  };

  static String _titleOf(AskPlace place) => switch (place) {
    AskPlace.payday => t.ask.places.payday,
    AskPlace.schedules => t.ask.places.schedules,
    AskPlace.tags => t.ask.places.tags,
    AskPlace.accounts => t.ask.places.accounts,
    AskPlace.categories => t.ask.places.categories,
    AskPlace.imports => t.ask.places.imports,
    AskPlace.inbox => t.ask.places.inbox,
    AskPlace.backup => t.ask.places.backup,
    AskPlace.help => t.ask.places.help,
    AskPlace.notifications => t.ask.places.notifications,
    AskPlace.reports => t.ask.places.reports,
    AskPlace.settings => t.ask.places.settings,
  };

  static String _lineOf(AskPlace place) => switch (place) {
    AskPlace.payday => t.ask.places.paydayText,
    AskPlace.schedules => t.ask.places.schedulesText,
    AskPlace.tags => t.ask.places.tagsText,
    AskPlace.accounts => t.ask.places.accountsText,
    AskPlace.categories => t.ask.places.categoriesText,
    AskPlace.imports => t.ask.places.importsText,
    AskPlace.inbox => t.ask.places.inboxText,
    AskPlace.backup => t.ask.places.backupText,
    AskPlace.help => t.ask.places.helpText,
    AskPlace.notifications => t.ask.places.notificationsText,
    AskPlace.reports => t.ask.places.reportsText,
    AskPlace.settings => t.ask.places.settingsText,
  };
}
