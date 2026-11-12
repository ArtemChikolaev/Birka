import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:money/money.dart';
import 'package:tags_common/tags_common.dart';

/// What a метка took (ADR 0027): the total in the base currency, a day on
/// the spot of a trip, the currencies, the categories and the operations.
///
/// It needs a [TagReportCubit] above it.
class TagReportPage extends StatelessWidget {
  /// Creates the page.
  const TagReportPage({
    required this.onBack,
    required this.onEdit,
    this.operations,
    super.key,
  });

  /// Called by the way back, and when the метка is gone.
  final VoidCallback onBack;

  /// Opens the form of the метка.
  final VoidCallback onEdit;

  /// The operations that wear the метка, as the host draws them.
  final Widget? operations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocConsumer<TagReportCubit, TagReportState>(
            listenWhen: (before, now) => before.status != now.status,
            listener: (context, state) {
              if (state.status == TagReportStatus.gone) onBack();
            },
            builder: (context, state) {
              final report = state.report;
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  BirkaTokens.spaceLg,
                  BirkaTokens.spaceXs,
                  BirkaTokens.spaceLg,
                  BirkaTokens.spaceXxl,
                ),
                children: [
                  BackHeader(
                    label: report?.tag.isTrip ?? true
                        ? t.tags.trip
                        : t.tags.tag,
                    backLabel: t.tags.back,
                    onBack: onBack,
                    trailing: report == null
                        ? null
                        : BirkaChip(
                            label: t.tags.edit,
                            selected: false,
                            onTap: onEdit,
                          ),
                  ),
                  const SizedBox(height: BirkaTokens.spaceLg),
                  if (state.status == TagReportStatus.failed)
                    Text(
                      t.tags.failed,
                      textAlign: TextAlign.center,
                      style: BirkaTextStyles.of(
                        context,
                      ).body.copyWith(color: BirkaColors.of(context).negative),
                    ),
                  if (report != null)
                    ..._report(context, report, state.today, operations),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static List<Widget> _report(
    BuildContext context,
    TagReport report,
    CivilDate today,
    Widget? operations,
  ) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    const gap = SizedBox(height: BirkaTokens.spaceLg);
    const small = SizedBox(height: BirkaTokens.spaceXs);
    return [
      _Summary(report: report, today: today),
      gap,
      _Stats(report: report, today: today),
      if (report.currencies.length > 1) ...[
        gap,
        SectionLabel(t.tags.report.currencies),
        small,
        _Currencies(report: report, today: today),
        small,
        Text(
          t.tags.report.ratesNote,
          style: styles.caption.copyWith(color: colors.textMuted),
        ),
      ],
      if (report.missingRates) ...[
        small,
        Text(
          t.tags.report.noRate,
          style: styles.caption.copyWith(color: colors.textMuted),
        ),
      ],
      if (report.categories.isNotEmpty) ...[
        gap,
        SectionLabel(t.tags.report.categories),
        small,
        GlassListGroup(
          children: [
            for (final part in report.categories)
              ShareLine(
                key: ValueKey(part.category?.id),
                color: _colorOf(part.category, colors),
                title: part.category?.name ?? t.tags.report.noCategory,
                note: '${part.percent}%',
                fraction: part.fraction,
                amount: AmountText(
                  formatMoney(part.total),
                  value: part.total.minorUnits,
                  style: styles.bodyStrong.copyWith(color: colors.text),
                ),
              ),
          ],
        ),
      ],
      if (report.isEmpty) ...[
        gap,
        Text(
          t.tags.report.nothing,
          textAlign: TextAlign.center,
          style: styles.body.copyWith(color: colors.textMuted),
        ),
      ] else if (operations != null) ...[
        gap,
        SectionLabel(t.tags.report.operations),
        small,
        operations,
      ],
    ];
  }

  static Color _colorOf(Category? category, BirkaColors colors) {
    final color = category?.color;
    return color == null ? colors.textMuted : BirkaColors.fromHex(color);
  }
}

/// The badge, the name, the total and the days.
class _Summary extends StatelessWidget {
  const _Summary({required this.report, required this.today});

  final TagReport report;
  final CivilDate today;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return Column(
      children: [
        ExcludeSemantics(
          child: GlyphBadge(
            glyph: report.tag.isTrip ? BirkaGlyph.plane : BirkaGlyph.tag,
            color: colors.accent,
            size: 72,
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceMd),
        Text(
          report.tag.name,
          textAlign: TextAlign.center,
          style: styles.heading.copyWith(color: colors.text),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AmountText(
            formatMoney(report.total),
            value: report.total.minorUnits,
            style: styles.display.copyWith(color: colors.text),
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        Text(
          reportLine(report, today: today),
          textAlign: TextAlign.center,
          style: styles.body.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}

/// A day on the spot, or a month of a метка without days, and how many
/// operations wear it.
class _Stats extends StatelessWidget {
  const _Stats({required this.report, required this.today});

  final TagReport report;
  final CivilDate today;

  @override
  Widget build(BuildContext context) {
    final perDay = report.perDay;
    final perMonth = report.perMonth;
    final first = switch ((perDay, perMonth)) {
      (final day?, _) => _Stat(
        label: t.tags.report.perDay,
        value: _about(report.perDayLocal ?? day),
        note: report.perDayLocal == null
            ? t.tags.report.forDays(n: report.elapsed)
            : formatMoney(day.roundedToWhole()),
      ),
      (null, final month?) => _Stat(
        label: t.tags.report.perMonth,
        value: _about(month),
        note: t.tags.report.forDays(n: report.span),
      ),
      _ => null,
    };
    final last = report.last;
    final count = _Stat(
      label: t.tags.report.count,
      value: '${report.operations.length}',
      note: report.tag.isTrip
          ? _split(report)
          : last == null
          ? ''
          : t.tags.report.last(
              date: dateLabel(
                year: last.year,
                month: last.month,
                day: last.day,
                thisYear: today.year,
              ),
            ),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (first != null) ...[
            Expanded(child: first),
            const SizedBox(width: BirkaTokens.spaceSm),
          ],
          Expanded(child: count),
        ],
      ),
    );
  }

  static String _about(Money amount) =>
      '≈ ${formatMoney(amount.roundedToWhole())}';

  /// `44 там, 2 заранее`, and nothing when every operation fell on the days.
  static String _split(TagReport report) {
    if (report.before == 0 && report.after == 0) return '';
    return [
      t.tags.report.there(n: report.there),
      if (report.before > 0) t.tags.report.before(n: report.before),
      if (report.after > 0) t.tags.report.after(n: report.after),
    ].join(', ');
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.note});

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: styles.caption.copyWith(color: colors.textMuted)),
          const SizedBox(height: BirkaTokens.spaceXxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              HiddenAmounts.mask(context, value),
              style: styles.amount.copyWith(color: colors.text),
            ),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: BirkaTokens.spaceXxs),
            Text(
              HiddenAmounts.mask(context, note),
              style: styles.caption.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// What the expenses took in each currency, and in the base one.
class _Currencies extends StatelessWidget {
  const _Currencies({required this.report, required this.today});

  final TagReport report;
  final CivilDate today;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return GlassListGroup(
      children: [
        for (final part in report.currencies)
          GlassListRow(
            key: ValueKey(part.amount.currency.code),
            leading: ExcludeSemantics(
              child: SizedBox.square(
                dimension: 36,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(BirkaTokens.radiusSm),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      currencySign(part.amount.currency),
                      style: styles.bodyStrong.copyWith(color: colors.text),
                    ),
                  ),
                ),
              ),
            ),
            title:
                t.app.currencies[part.amount.currency.code] ??
                part.amount.currency.code,
            subtitle: _line(part),
            trailing: _Amounts(part: part, base: report.base),
          ),
      ],
    );
  }

  String _line(TagCurrencyPart part) {
    final only = part.only;
    if (only != null) {
      final day = only.occurredOn;
      final date = dateLabel(
        year: day.year,
        month: day.month,
        day: day.day,
        thisYear: today.year,
      );
      final note = only.note.trim();
      return note.isEmpty ? date : '$note, $date';
    }
    if (report.tag.isTrip && part.there == part.count) {
      return t.tags.report.onTheSpot(n: part.count);
    }
    return t.tags.operations(n: part.count);
  }
}

class _Amounts extends StatelessWidget {
  const _Amounts({required this.part, required this.base});

  final TagCurrencyPart part;
  final Currency base;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final inBase = part.inBase;
    final own = HiddenAmounts.mask(context, formatMoney(part.amount));
    if (part.amount.currency == base || inBase == null) {
      return Text(own, style: styles.bodyStrong.copyWith(color: colors.text));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          HiddenAmounts.mask(context, formatMoney(inBase)),
          style: styles.bodyStrong.copyWith(color: colors.text),
        ),
        Text(own, style: styles.caption.copyWith(color: colors.textMuted)),
      ],
    );
  }
}
