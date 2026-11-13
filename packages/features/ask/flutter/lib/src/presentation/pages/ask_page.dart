import 'dart:async';

import 'package:ask_common/ask_common.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// «Спросить» (ADR 0028): a field that takes a question about money in
/// words, and below it the examples and the questions asked last, or the
/// answer: plaques of what the question was read as and what the ledger
/// says, a fact, the help, screens, or a fixed reply.
///
/// It needs an [AskCubit] above it.
class AskPage extends StatefulWidget {
  /// Creates the page.
  const AskPage({
    required this.onBack,
    required this.onShowOperations,
    required this.onOpenPlace,
    required this.onOpenHelp,
    this.onOpenOperation,
    this.onOpenTag,
    this.fact,
    super.key,
  });

  /// Goes back.
  final VoidCallback onBack;

  /// Opens the operations that an answer counted, under its title.
  final void Function(AskAnswer answer, String title) onShowOperations;

  /// Opens a screen.
  final ValueChanged<AskPlace> onOpenPlace;

  /// Opens the help, where the person can also write to the developer.
  final VoidCallback onOpenHelp;

  /// Opens the card of an operation by its id.
  final ValueChanged<String>? onOpenOperation;

  /// Opens the report of a метка by its id.
  final ValueChanged<String>? onOpenTag;

  /// The card of a fact that another feature keeps, such as what can be
  /// spent today and the next payments, or `null` to lead to its screen.
  final Widget? Function(BuildContext context, AskFact fact)? fact;

  @override
  State<AskPage> createState() => _AskPageState();
}

class _AskPageState extends State<AskPage> {
  final _field = TextEditingController();
  Timer? _wait;
  Timer? _typing;

  @override
  void dispose() {
    _wait?.cancel();
    _typing?.cancel();
    _field.dispose();
    super.dispose();
  }

  AskCubit get _cubit => context.read<AskCubit>();

  /// A question being typed is read once the fingers pause.
  void _changed(String text) {
    _typing?.cancel();
    _wait?.cancel();
    if (text.trim().isEmpty) return _cubit.ask('');
    _wait = Timer(const Duration(milliseconds: 380), () {
      if (mounted) _cubit.ask(text);
    });
  }

  void _submitted(String text) {
    _wait?.cancel();
    _cubit.ask(text);
    unawaited(_cubit.remember());
  }

  /// Types [question] into the field as a finger would, then asks it.
  void _type(String question) {
    _wait?.cancel();
    _typing?.cancel();
    FocusScope.of(context).unfocus();
    if (BirkaMotion.reduced(context)) {
      _field.text = question;
      return _submitted(question);
    }
    var shown = 0;
    _typing = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (!mounted) return timer.cancel();
      shown++;
      _field.value = TextEditingValue(
        text: question.substring(0, shown),
        selection: TextSelection.collapsed(offset: shown),
      );
      if (shown < question.length) return;
      timer.cancel();
      _submitted(question);
    });
  }

  /// Keeps the question among those asked last, then does [open].
  void _leave(VoidCallback open) {
    unawaited(_cubit.remember());
    open();
  }

  Future<void> _pickPeriod(AskState state, AskPeriod current) async {
    final picked = await showChoiceSheet<AskPeriod>(
      context,
      title: t.ask.period.title,
      subtitle: t.ask.period.subtitle,
      choices: state.periods,
      selected: current,
      labelOf: (period) => periodLabel(period, today: state.today),
      subtitleOf: (period) => periodLine(period, today: state.today),
    );
    if (picked == null || !mounted) return;
    _cubit.choosePeriod(picked.$1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
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
                    GlassIconButton(
                      glyph: BirkaGlyph.back,
                      label: t.ask.back,
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: BirkaTokens.spaceSm),
                    Expanded(
                      child: GlassSearchField(
                        label: t.ask.title,
                        hint: t.ask.hint,
                        clearLabel: t.ask.clear,
                        controller: _field,
                        onChanged: _changed,
                        onSubmitted: _submitted,
                        autofocus: true,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<AskCubit, AskState>(
                  builder: (context, state) => ScrollEdgeFade(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        BirkaTokens.spaceLg,
                        BirkaTokens.spaceSm,
                        BirkaTokens.spaceLg,
                        BirkaTokens.spaceXxl,
                      ),
                      children: [
                        AnimatedSwitcher(
                          duration: BirkaMotion.reduced(context)
                              ? Duration.zero
                              : BirkaMotion.slow,
                          switchInCurve: BirkaMotion.standardCurve,
                          switchOutCurve: BirkaMotion.fadeCurve,
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topCenter,
                            children: [...previous, ?current],
                          ),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: const Offset(0, 0.02),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: KeyedSubtree(
                            key: ValueKey(_topic(state.reading)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: switch (state.reading) {
                                // The examples wait for the categories and
                                // the метки, so that they do not shuffle.
                                null when !state.ready => const [],
                                null => _start(state),
                                final reading => _answer(state, reading),
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// What a reading is about, without its period: the answer of another
  /// period rolls in place, and another question comes in anew.
  static String _topic(AskReading? reading) => switch (reading) {
    null => 'start',
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

  // ---------------------------------------------------------------- start

  List<Widget> _start(AskState state) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return [
      SectionLabel(t.ask.examples),
      const SizedBox(height: BirkaTokens.spaceXs),
      GlassListGroup(
        children: [
          for (final example in state.examples)
            GlassListRow(
              key: ValueKey(example.kind),
              leading: ExcludeSemantics(child: _exampleBadge(example)),
              title: example.question,
              subtitle: example.line,
              trailing: BirkaIcon(
                BirkaGlyph.chevron,
                size: 16,
                color: colors.textMuted,
              ),
              onTap: () => _type(example.question),
            ),
        ],
      ),
      AnimatedSize(
        duration: BirkaMotion.reduced(context)
            ? Duration.zero
            : BirkaMotion.base,
        curve: BirkaMotion.standardCurve,
        alignment: Alignment.topCenter,
        child: state.recent.isEmpty
            ? const SizedBox(width: double.infinity)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: BirkaTokens.spaceLg),
                  Row(
                    children: [
                      Expanded(child: SectionLabel(t.ask.recent)),
                      AccentLink(
                        label: t.ask.forget,
                        chevron: false,
                        onTap: () => unawaited(_cubit.forget()),
                      ),
                    ],
                  ),
                  const SizedBox(height: BirkaTokens.spaceXs),
                  GlassListGroup(
                    children: [
                      for (final question in state.recent)
                        GlassListRow(
                          key: ValueKey(question),
                          leading: BirkaIcon(
                            BirkaGlyph.search,
                            size: 18,
                            color: colors.textMuted,
                          ),
                          title: question,
                          onTap: () => _type(question),
                        ),
                    ],
                  ),
                ],
              ),
      ),
      const SizedBox(height: BirkaTokens.spaceLg),
      Text(
        t.ask.private,
        textAlign: TextAlign.center,
        style: styles.caption.copyWith(color: colors.textMuted),
      ),
    ];
  }

  Widget _exampleBadge(AskExample example) {
    final colors = BirkaColors.of(context);
    final category = example.category;
    final (glyph, color) = switch (example.kind) {
      AskExampleKind.category => (
        BirkaGlyph.named(category?.icon),
        _colorOf(category) ?? colors.accent,
      ),
      AskExampleKind.trip => (BirkaGlyph.plane, colors.accent),
      AskExampleKind.big => (BirkaGlyph.rise, colors.negative),
      AskExampleKind.allowance => (BirkaGlyph.wallet, colors.accent),
      AskExampleKind.payments => (BirkaGlyph.repeat, colors.accent),
      AskExampleKind.help => (BirkaGlyph.book, colors.textSecondary),
    };
    return GlyphBadge(glyph: glyph, color: color);
  }

  // ---------------------------------------------------------------- answers

  List<Widget> _answer(AskState state, AskReading reading) => switch (reading) {
    AskData() => _data(state, reading),
    AskFactReading(:final fact) => _fact(state, fact),
    AskHelpReading(:final questions, :final places) => [
      ..._help(questions),
      ..._places(places),
    ],
    AskPlacesReading(:final places) => _places(places),
    AskRefused(:final reason) => _refused(state, reason),
    AskUnknown() => _unknown(state),
  };

  List<Widget> _data(AskState state, AskData reading) {
    final query = reading.query;
    final answer = state.answer;
    final title = answerTitle(query, state.names, today: state.today);
    return [
      _Chips(
        chips: state.chips,
        period: query.period,
        onPeriod: (period) => unawaited(_pickPeriod(state, period)),
      ),
      if (answer != null) ...[
        const SizedBox(height: BirkaTokens.spaceLg),
        _AnswerCard(
          answer: answer,
          title: title,
          today: state.today,
          onShow: () => _leave(() => widget.onShowOperations(answer, title)),
        ),
        ..._operations(state, answer),
        ..._shares(answer),
        if (state.names.tags[query.tagId] case final tag? when tag.isTrip)
          ..._link(
            title: t.ask.answer.trip,
            subtitle: t.ask.answer.tripText,
            glyph: BirkaGlyph.plane,
            onTap: widget.onOpenTag == null
                ? null
                : () => _leave(() => widget.onOpenTag!(tag.id)),
          ),
        ..._places(reading.places),
        const SizedBox(height: BirkaTokens.spaceLg),
        _Caption(
          answer.partial ? t.ask.answer.partial : t.ask.answer.counted,
        ),
      ],
    ];
  }

  List<Widget> _operations(AskState state, AskAnswer answer) {
    final query = answer.query;
    final all =
        query.above != null || query.below != null || query.words.isNotEmpty;
    final shown = all ? answer.operations.take(20) : answer.biggest;
    if (shown.isEmpty) return const [];
    return [
      const SizedBox(height: BirkaTokens.spaceLg),
      SectionLabel(all ? t.ask.answer.operationsTitle : t.ask.answer.biggest),
      const SizedBox(height: BirkaTokens.spaceXs),
      GlassListGroup(
        children: [
          for (final operation in shown)
            _OperationRow(
              key: ValueKey(operation.transaction.id),
              operation: operation,
              state: state,
              onTap: widget.onOpenOperation == null
                  ? null
                  : () => _leave(
                      () => widget.onOpenOperation!(operation.transaction.id),
                    ),
            ),
        ],
      ),
    ];
  }

  List<Widget> _shares(AskAnswer answer) {
    final shares = answer.shares;
    if (shares.length < 2) return const [];
    final colors = BirkaColors.of(context);
    final top = shares.first.total.minorUnits;
    return [
      const SizedBox(height: BirkaTokens.spaceLg),
      SectionLabel(
        answer.query.side == AskSide.income
            ? t.ask.answer.sharesIncome
            : t.ask.answer.sharesExpenses,
      ),
      const SizedBox(height: BirkaTokens.spaceXs),
      GlassSurface(
        child: Column(
          children: [
            for (final (i, share) in shares.indexed) ...[
              if (i > 0) const SizedBox(height: BirkaTokens.spaceMd),
              ShareLine(
                key: ValueKey(share.category?.id),
                color: _colorOf(share.category) ?? colors.textMuted,
                title: share.category?.name ?? t.ask.answer.noCategory,
                amount: AmountText(formatMoney(share.total)),
                fraction: top == 0 ? 0 : share.total.minorUnits / top,
                note: '${share.percent}%',
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _fact(AskState state, AskFact fact) => switch (fact) {
    AskFact.allowance || AskFact.payments => [
      widget.fact?.call(context, fact) ?? const SizedBox.shrink(),
      ..._places([
        if (fact == AskFact.allowance) AskPlace.payday else AskPlace.schedules,
      ]),
    ],
    AskFact.capital => _capital(state),
    AskFact.rate => _rate(state),
  };

  List<Widget> _capital(AskState state) {
    final capital = state.capital;
    final main = capital?.main;
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final accounts = [
      for (final balance in state.balances)
        if (balance.account.includeInTotals && !balance.account.archived)
          balance,
    ];
    return [
      GlassSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(
              t.ask.fact.capital(
                currencies: t.overview.currencies(n: capital?.currencies ?? 0),
              ),
            ),
            const SizedBox(height: BirkaTokens.spaceXs),
            AmountText(
              main == null ? '—' : formatMoney(main),
              value: main?.minorUnits,
              style: styles.display,
            ),
            const SizedBox(height: BirkaTokens.spaceXxs),
            Text(
              t.ask.fact.accounts(n: accounts.length),
              style: styles.body.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
      if (accounts.isNotEmpty) ...[
        const SizedBox(height: BirkaTokens.spaceLg),
        GlassListGroup(
          children: [
            for (final balance in accounts)
              GlassListRow(
                key: ValueKey(balance.account.id),
                title: balance.account.name,
                trailing: AmountText(formatMoney(balance.balance)),
              ),
          ],
        ),
      ],
      ..._link(
        title: t.ask.fact.allAccounts,
        subtitle: t.ask.fact.allAccountsText,
        glyph: BirkaGlyph.wallet,
        onTap: () => _leave(() => widget.onOpenPlace(AskPlace.accounts)),
      ),
    ];
  }

  List<Widget> _rate(AskState state) {
    final reading = state.reading;
    final currency = reading is AskFactReading ? reading.currency : null;
    final rate = state.rate;
    final day = state.rates.latestDay;
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return [
      GlassSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: BirkaTokens.spaceXs),
            if (rate == null || currency == null)
              Text(
                t.ask.fact.rateMissing,
                style: styles.body.copyWith(color: colors.textSecondary),
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AmountText(
                    formatMoney(rate),
                    alwaysShown: true,
                    style: styles.display,
                  ),
                  const SizedBox(width: BirkaTokens.spaceXs),
                  Text(
                    t.ask.fact.rateFor(sign: currencySign(currency)),
                    style: styles.body.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: BirkaTokens.spaceXxs),
              Text(
                t.ask.fact.rateKept,
                style: styles.body.copyWith(color: colors.textSecondary),
              ),
            ],
          ],
        ),
      ),
      ..._link(
        title: t.ask.fact.rateHelp,
        subtitle: t.ask.fact.rateHelpText,
        glyph: BirkaGlyph.book,
        onTap: () => _leave(widget.onOpenHelp),
      ),
    ];
  }

  List<Widget> _help(List<int> questions) {
    final all = helpQuestions();
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return [
      SectionLabel(t.ask.help.title),
      const SizedBox(height: BirkaTokens.spaceXs),
      GlassSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final index in questions)
              if (index < all.length) ...[
                Text(
                  all[index].question,
                  style: styles.bodyStrong.copyWith(color: colors.text),
                ),
                const SizedBox(height: BirkaTokens.spaceXs),
                Text(
                  all[index].answer,
                  style: styles.body.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: BirkaTokens.spaceMd),
              ],
            AccentLink(
              label: t.ask.help.all,
              expand: true,
              onTap: () => _leave(widget.onOpenHelp),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _places(List<AskPlace> places) {
    if (places.isEmpty) return const [];
    final colors = BirkaColors.of(context);
    return [
      const SizedBox(height: BirkaTokens.spaceLg),
      SectionLabel(t.ask.places.title),
      const SizedBox(height: BirkaTokens.spaceXs),
      GlassListGroup(
        children: [
          for (final place in places)
            GlassListRow(
              key: ValueKey(place),
              leading: ExcludeSemantics(
                child: GlyphBadge(glyph: _glyphOf(place), color: colors.accent),
              ),
              title: _titleOf(place),
              subtitle: _lineOf(place),
              trailing: BirkaIcon(
                BirkaGlyph.chevron,
                size: 16,
                color: colors.textMuted,
              ),
              onTap: () => _leave(() => widget.onOpenPlace(place)),
            ),
        ],
      ),
    ];
  }

  List<Widget> _refused(AskState state, AskRefusal reason) {
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
      _Reply(title: title, text: text, glyph: BirkaGlyph.alert),
      ..._suggestions(suggestions),
    ];
  }

  List<Widget> _unknown(AskState state) => [
    _Reply(
      title: t.ask.refused.unknown,
      text: t.ask.refused.unknownText,
      glyph: BirkaGlyph.search,
    ),
    ..._suggestions([
      for (final example in state.examples.take(3)) example.question,
    ]),
    ..._link(
      title: t.ask.refused.write,
      subtitle: t.ask.refused.writeText,
      glyph: BirkaGlyph.book,
      onTap: () => _leave(widget.onOpenHelp),
    ),
  ];

  List<Widget> _suggestions(List<String> questions) => [
    const SizedBox(height: BirkaTokens.spaceLg),
    SectionLabel(t.ask.refused.suggest),
    const SizedBox(height: BirkaTokens.spaceXs),
    Wrap(
      spacing: BirkaTokens.spaceXs,
      runSpacing: BirkaTokens.spaceXs,
      children: [
        for (final question in questions)
          BirkaChip(
            label: question,
            selected: false,
            onTap: () => _type(question),
          ),
      ],
    ),
  ];

  List<Widget> _link({
    required String title,
    required String subtitle,
    required BirkaGlyph glyph,
    required VoidCallback? onTap,
  }) {
    if (onTap == null) return const [];
    final colors = BirkaColors.of(context);
    return [
      const SizedBox(height: BirkaTokens.spaceLg),
      GlassListGroup(
        children: [
          GlassListRow(
            leading: ExcludeSemantics(
              child: GlyphBadge(glyph: glyph, color: colors.accent),
            ),
            title: title,
            subtitle: subtitle,
            trailing: BirkaIcon(
              BirkaGlyph.chevron,
              size: 16,
              color: colors.textMuted,
            ),
            onTap: onTap,
          ),
        ],
      ),
    ];
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

Color? _colorOf(Category? category) {
  final color = category?.color;
  return color == null ? null : BirkaColors.fromHex(color);
}

/// The plaques of what a question about money was read as. The plaque of
/// the days opens the sheet of periods, and its label slides to a new one.
class _Chips extends StatelessWidget {
  const _Chips({
    required this.chips,
    required this.period,
    required this.onPeriod,
  });

  final List<AskChip> chips;
  final AskPeriod? period;
  final ValueChanged<AskPeriod> onPeriod;

  @override
  Widget build(BuildContext context) {
    final period = this.period;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(t.ask.understood),
        const SizedBox(height: BirkaTokens.spaceXs),
        Wrap(
          spacing: BirkaTokens.spaceXs,
          runSpacing: BirkaTokens.spaceXs,
          children: [
            for (final chip in chips)
              BirkaChip(
                key: ValueKey(chip.kind),
                label: chip.label,
                selected: true,
                glyph: switch (chip.kind) {
                  AskChipKind.category => BirkaGlyph.named(
                    chip.category?.icon,
                  ),
                  AskChipKind.tag =>
                    chip.tag?.isTrip ?? false
                        ? BirkaGlyph.plane
                        : BirkaGlyph.tag,
                  AskChipKind.account => BirkaGlyph.wallet,
                  AskChipKind.period => BirkaGlyph.calendar,
                  _ => null,
                },
                trailingGlyph: chip.kind == AskChipKind.period && period != null
                    ? BirkaGlyph.chevron
                    : null,
                trailingTurns: 1,
                order: chip.kind == AskChipKind.period ? period?.first : null,
                onTap: chip.kind == AskChipKind.period && period != null
                    ? () => onPeriod(period)
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

/// What the ledger says: the title, the total that rolls to a new one, the
/// count and the mean, the change against the stretch before, the bars and
/// the way to the operations.
class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.answer,
    required this.title,
    required this.today,
    required this.onShow,
  });

  final AskAnswer answer;
  final String title;
  final CivilDate today;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final income = answer.query.side == AskSide.income;
    final period = answer.query.period;
    final before = answer.before;
    final change = before == null ? null : answer.total - before;
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: BirkaTokens.spaceXs),
          AmountText(
            income ? signedMoney(answer.total) : formatMoney(answer.total),
            value: answer.total.minorUnits,
            rise: income ? AmountRise.good : AmountRise.bad,
            tone: income ? AmountTone.positive : AmountTone.neutral,
            style: styles.display,
          ),
          const SizedBox(height: BirkaTokens.spaceXxs),
          FadingText(
            answer.count == 0 ? t.ask.answer.none : answerLine(answer),
            style: styles.body.copyWith(color: colors.textSecondary),
          ),
          if (change != null && period != null && !change.isZero) ...[
            const SizedBox(height: BirkaTokens.spaceSm),
            Wrap(
              spacing: BirkaTokens.spaceXs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                BirkaChangePill(
                  label: signedMoney(change),
                  rise: change.isPositive,
                  good: income ? change.isPositive : change.isNegative,
                  value: change.minorUnits,
                ),
                FadingText(
                  beforeLabel(period, today: today),
                  style: styles.caption.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ],
          if (answer.bars.isNotEmpty) ...[
            const SizedBox(height: BirkaTokens.spaceMd),
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
          ],
          if (answer.count == 0)
            Padding(
              padding: const EdgeInsets.only(top: BirkaTokens.spaceXs),
              child: Text(
                t.ask.answer.noneText,
                style: styles.caption.copyWith(color: colors.textMuted),
              ),
            )
          else ...[
            const SizedBox(height: BirkaTokens.spaceMd),
            BirkaButton(
              label: t.ask.answer.show(n: answer.count),
              quiet: true,
              onPressed: onShow,
            ),
          ],
        ],
      ),
    );
  }
}

/// An operation of an answer: its note or category, its day and account,
/// and what it took, with what that came to in the currency of the answer.
class _OperationRow extends StatelessWidget {
  const _OperationRow({
    required this.operation,
    required this.state,
    required this.onTap,
    super.key,
  });

  final AskOperation operation;
  final AskState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final transaction = operation.transaction;
    final allocation = transaction.allocations.firstOrNull;
    final category = state.names.categories[allocation?.categoryId];
    final account = state.names.accounts[transaction.entries.first.accountId];
    final day = transaction.occurredOn;
    final income = transaction.kind == TransactionKind.income;
    final amount = income ? operation.amount : -operation.amount;
    final counted = operation.counted;
    return GlassListRow(
      leading: ExcludeSemantics(
        child: GlyphBadge(
          glyph: BirkaGlyph.named(category?.icon),
          color: _colorOf(category) ?? colors.textMuted,
        ),
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
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AmountText(
            signedMoney(amount),
            tone: income ? AmountTone.positive : AmountTone.neutral,
          ),
          if (counted != null && counted.currency != operation.amount.currency)
            AmountText(
              '≈ ${formatMoney(counted)}',
              tone: AmountTone.muted,
              style: styles.caption,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// A fixed reply: what Birka does not answer, and why.
class _Reply extends StatelessWidget {
  const _Reply({required this.title, required this.text, required this.glyph});

  final String title;
  final String text;
  final BirkaGlyph glyph;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return GlassSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: GlyphBadge(glyph: glyph, color: colors.textSecondary),
          ),
          const SizedBox(width: BirkaTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: styles.heading.copyWith(color: colors.text)),
                const SizedBox(height: BirkaTokens.spaceXxs),
                Text(
                  text,
                  style: styles.body.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: BirkaTextStyles.of(
      context,
    ).caption.copyWith(color: BirkaColors.of(context).textMuted),
  );
}
