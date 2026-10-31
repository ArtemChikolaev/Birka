import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:reports_common/reports_common.dart';

/// What a month took or brought, by category and against the months before.
///
/// It lives in a tab under the navigation bar, and needs a [ReportsCubit]
/// above it.
class ReportsPage extends StatefulWidget {
  /// Creates the page.
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(context.read<ReportsCubit>().calendarChecked()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: BirkaTokens.spaceLg);
    return SafeArea(
      bottom: false,
      // Glass panels share one backdrop, which keeps scrolling smooth.
      child: BackdropGroup(
        child: BlocBuilder<ReportsCubit, ReportsState>(
          builder: (context, state) {
            final cubit = context.read<ReportsCubit>();
            final report = state.report;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                BirkaTokens.spaceLg,
                BirkaTokens.spaceLg,
                BirkaTokens.spaceLg,
                GlassNavBar.clearance +
                    MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: [
                _Header(state: state),
                const SizedBox(height: BirkaTokens.spaceMd),
                GlassSegmented<CategoryKind>(
                  segments: {
                    for (final kind in CategoryKind.values)
                      kind: kindLabel(kind),
                  },
                  selected: state.kind,
                  onChanged: (kind) => unawaited(cubit.kindChanged(kind)),
                ),
                gap,
                ...switch (state.status) {
                  ReportsStatus.loading => const <Widget>[],
                  ReportsStatus.failed => [const _Failure()],
                  ReportsStatus.ready => [
                    if (report.isEmpty)
                      _Empty(kind: state.kind)
                    else ...[
                      Center(child: _Ring(state: state)),
                      gap,
                      _Lines(report: report, kind: state.kind),
                    ],
                    if (report.others.isNotEmpty) ...[
                      const SizedBox(height: BirkaTokens.spaceSm),
                      _Others(amounts: report.others),
                    ],
                    if (report.average != null) ...[
                      gap,
                      _Months(report: report),
                    ],
                  ],
                },
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final ReportsState state;

  Future<void> _pickMonth(BuildContext context) async {
    final cubit = context.read<ReportsCubit>();
    final colors = BirkaColors.of(context);
    final months = await cubit.months();
    if (!context.mounted) return;
    final picked = await showModalBottomSheet<CivilDate>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: colors.background,
      builder: (context) => ChoiceSheet(
        title: t.transactions.pickMonth,
        children: [
          GlassListGroup(
            children: [
              for (final month in months)
                GlassListRow(
                  title: reportMonthLabel(month, today: state.today),
                  trailing: month == state.month
                      ? BirkaIcon(BirkaGlyph.check, color: colors.accent)
                      : null,
                  onTap: () => Navigator.of(context).pop(month),
                ),
            ],
          ),
        ],
      ),
    );
    if (picked != null) await cubit.monthChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            t.app.reports,
            style: BirkaTextStyles.of(
              context,
            ).title.copyWith(color: BirkaColors.of(context).text),
          ),
        ),
        const SizedBox(width: BirkaTokens.spaceXs),
        BirkaChip(
          glyph: BirkaGlyph.calendar,
          label: reportMonthLabel(state.month, today: state.today),
          selected: false,
          onTap: () => _pickMonth(context),
        ),
      ],
    );
  }
}

/// The color of a category, whose color is its own choice.
Color _colorOf(Category category, BirkaColors colors) {
  final color = category.color;
  return color == null ? colors.textSubtle : BirkaColors.fromHex(color);
}

/// How a change reads: a rise of expenses is bad news, and of income good news.
Color _toneOf(int percent, CategoryKind kind, BirkaColors colors) {
  if (percent == 0) return colors.textMuted;
  final good = (percent > 0) == (kind == CategoryKind.income);
  return good ? colors.positive : colors.negative;
}

/// The big ring with the total of the month in the middle.
class _Ring extends StatelessWidget {
  const _Ring({required this.state});

  final ReportsState state;

  static const double _size = 196;
  static const double _thickness = 18;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final report = state.report;
    final change = report.change;
    return BirkaRing(
      size: _size,
      thickness: _thickness,
      label: t.reports.ring,
      slices: [
        for (final line in report.lines)
          RingSlice(
            line.total.minorUnits.toDouble(),
            _colorOf(line.category, colors),
          ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionLabel(kindLabel(state.kind), color: colors.textMuted),
          const SizedBox(height: BirkaTokens.spaceXxs),
          AmountText(
            formatMoney(report.total!),
            style: styles.heading.copyWith(color: colors.text),
          ),
          if (change != null) ...[
            const SizedBox(height: BirkaTokens.spaceXxs),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                changeAgainst(change, month: state.month),
                maxLines: 1,
                style: styles.caption.copyWith(
                  color: _toneOf(change, state.kind, colors),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Each category with its change, its amount and a bar against the biggest one.
class _Lines extends StatelessWidget {
  const _Lines({required this.report, required this.kind});

  final Report report;
  final CategoryKind kind;

  @override
  Widget build(BuildContext context) {
    return GlassListGroup(
      children: [
        for (final line in report.lines) _Line(line: line, kind: kind),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line, required this.kind});

  final ReportLine line;
  final CategoryKind kind;

  static const double _dot = 10;
  static const double _bar = 4;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final color = _colorOf(line.category, colors);
    final change = line.change;
    return Padding(
      padding: const EdgeInsets.all(BirkaTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: _dot,
                height: _dot,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: BirkaTokens.spaceXs),
              Expanded(
                child: Text(
                  line.category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.bodyStrong.copyWith(color: colors.text),
                ),
              ),
              if (change != null) ...[
                const SizedBox(width: BirkaTokens.spaceXs),
                Text(
                  percentLabel(change),
                  style: styles.caption.copyWith(
                    color: _toneOf(change, kind, colors),
                  ),
                ),
              ],
              const SizedBox(width: BirkaTokens.spaceSm),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AmountText(
                    formatMoney(line.total),
                    style: styles.bodyStrong.copyWith(color: colors.text),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(BirkaTokens.radiusXs),
            ),
            child: ColoredBox(
              color: colors.surfaceRaised,
              child: SizedBox(
                height: _bar,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: line.share,
                  child: ColoredBox(color: color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the month took in the currencies that the report does not follow.
class _Others extends StatelessWidget {
  const _Others({required this.amounts});

  final List<Money> amounts;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AmountText(
        amounts.map(formatMoney).join(' · '),
        tone: AmountTone.muted,
        style: BirkaTextStyles.of(context).caption,
      ),
    );
  }
}

/// The last months as bars.
class _Months extends StatelessWidget {
  const _Months({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final average = report.average!;
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionLabel(t.reports.byMonth, color: colors.text),
              Flexible(
                child: Text(
                  // A compact amount would tell its size by its word.
                  averageLabel(
                    HiddenAmounts.of(context)
                        ? HiddenAmounts.mask(context, formatMoney(average))
                        : formatCompactMoney(average),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.caption.copyWith(color: colors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          BirkaBars(
            bars: [
              for (final (index, month) in report.months.indexed)
                BirkaBar(
                  value: month.total.minorUnits.toDouble(),
                  amount: formatCompactFigure(month.total),
                  label: shortMonthLabel(month.month),
                  highlighted: index == report.months.length - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.kind});

  final CategoryKind kind;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(BirkaTokens.spaceLg),
      child: Text(
        emptyLabel(kind),
        style: BirkaTextStyles.of(
          context,
        ).body.copyWith(color: BirkaColors.of(context).textMuted),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(BirkaTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.reports.failed,
            style: BirkaTextStyles.of(
              context,
            ).body.copyWith(color: BirkaColors.of(context).text),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          BirkaButton(
            label: t.app.retry,
            onPressed: () => context.read<ReportsCubit>().retry(),
          ),
        ],
      ),
    );
  }
}
