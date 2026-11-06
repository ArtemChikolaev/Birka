import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:import_common/import_common.dart';
import 'package:import_flutter/src/presentation/widgets/table_card.dart';
import 'package:l10n/l10n.dart';

/// The columns of a file of no format that Birka knows, on the phone, as
/// their board draws them: what each column holds, how its amounts and dates
/// are written, and the first rows as they will come into the ledger. It
/// closes with `true` once the rows read. It needs an [ImportCubit] above it.
class ImportColumnsPage extends StatelessWidget {
  /// Creates the page.
  const ImportColumnsPage({super.key});

  /// How many rows the preview shows.
  static const shown = 4;

  /// The roles that the sheet of a column offers, as the board names them;
  /// the role a column has stays among them.
  static const List<ColumnRole> roles = [
    ColumnRole.date,
    ColumnRole.amount,
    ColumnRole.expense,
    ColumnRole.income,
    ColumnRole.currency,
    ColumnRole.description,
    ColumnRole.category,
    ColumnRole.balance,
    ColumnRole.skip,
  ];

  Future<void> _chooseRole(
    BuildContext context,
    ImportCubit cubit,
    StatementColumn column,
    ColumnRole role,
  ) async {
    final picked = await showChoiceSheet<ColumnRole>(
      context,
      title: t.imports.roleOf(header: _nameOf(column)),
      choices: [
        ...roles,
        if (!roles.contains(role)) role,
      ],
      selected: role,
      labelOf: (role) => t.imports.roles[role.name] ?? role.name,
      subtitleOf: (role) => t.imports.roleNotes[role.name],
    );
    if (picked != null) cubit.setRole(column.index, picked.$1);
  }

  static String _nameOf(StatementColumn column) {
    final header = column.header.trim();
    return header.isEmpty ? '${column.index + 1}' : header;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<ImportCubit, ImportState>(
            builder: (context, state) {
              final cubit = context.read<ImportCubit>();
              final table = state.table;
              final layout = state.layout;
              final statement = state.statement;
              if (table == null || layout == null || statement == null) {
                return const SizedBox.shrink();
              }
              final count = statement.rows.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BirkaTokens.spaceLg,
                      BirkaTokens.spaceLg,
                      BirkaTokens.spaceLg,
                      BirkaTokens.spaceXs,
                    ),
                    child: BackHeader(
                      label: t.imports.columnsHeading,
                      backLabel: t.imports.back,
                      onBack: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  Expanded(
                    child: ScrollEdgeFade(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BirkaTokens.spaceLg,
                          vertical: BirkaTokens.spaceXs,
                        ),
                        children: [
                          TableCard(table: table),
                          const SizedBox(height: BirkaTokens.spaceMd),
                          _Quiet(t.imports.columnsText),
                          const SizedBox(height: BirkaTokens.spaceLg),
                          SectionLabel(t.imports.columnsTitle),
                          const SizedBox(height: BirkaTokens.spaceXs),
                          GlassListGroup(
                            children: [
                              for (final column in layout.columns)
                                if (column.header.trim().isNotEmpty ||
                                    !column.sample.isBlank)
                                  GlassListRow(
                                    title: _nameOf(column),
                                    subtitle: column.sample.isBlank
                                        ? '—'
                                        : column.sample.text.trim(),
                                    trailing: GlassListValue(
                                      t.imports.roles[layout
                                              .roles[column.index]
                                              .name] ??
                                          '',
                                    ),
                                    onTap: () => _chooseRole(
                                      context,
                                      cubit,
                                      column,
                                      layout.roles[column.index],
                                    ),
                                  ),
                            ],
                          ),
                          const SizedBox(height: BirkaTokens.spaceLg),
                          _Options(options: layout.options, cubit: cubit),
                          _Missing(shown: layout.missing.isNotEmpty),
                          const SizedBox(height: BirkaTokens.spaceLg),
                          _Preview(state: state),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      BirkaTokens.spaceLg,
                      BirkaTokens.spaceSm,
                      BirkaTokens.spaceLg,
                      BirkaTokens.spaceLg + bottom,
                    ),
                    child: BirkaButton(
                      label: state.readable
                          ? t.imports.columnsDone(
                              operations: operationsLabel(count),
                            )
                          : t.imports.finish,
                      onPressed: state.readable
                          ? () => Navigator.of(context).pop(true)
                          : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// How the amounts and the dates of the file are written.
class _Options extends StatelessWidget {
  const _Options({required this.options, required this.cubit});

  final ReadingOptions options;
  final ImportCubit cubit;

  @override
  Widget build(BuildContext context) {
    Widget option(String label, Widget control) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: BirkaTextStyles.of(
            context,
          ).caption.copyWith(color: BirkaColors.of(context).textMuted),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        control,
      ],
    );
    return GlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          option(
            t.imports.signTitle,
            GlassSegmented<AmountSign>(
              segments: {
                for (final sign in AmountSign.values)
                  sign: t.imports.signs[sign.name] ?? sign.name,
              },
              selected: options.sign,
              onChanged: (sign) =>
                  cubit.setOptions(options.copyWith(sign: sign)),
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          option(
            t.imports.markTitle,
            GlassSegmented<DecimalMark>(
              segments: {
                for (final mark in DecimalMark.values)
                  mark: t.imports.marks[mark.name] ?? mark.name,
              },
              selected: options.decimalMark,
              onChanged: (mark) =>
                  cubit.setOptions(options.copyWith(decimalMark: mark)),
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          option(
            t.imports.datesTitle,
            GlassSegmented<DateOrder>(
              segments: {
                for (final order in DateOrder.values)
                  order: t.imports.dateOrders[order.name] ?? order.name,
              },
              selected: options.dateOrder,
              onChanged: (order) =>
                  cubit.setOptions(options.copyWith(dateOrder: order)),
            ),
          ),
        ],
      ),
    );
  }
}

/// What a file without the column of its dates or amounts lacks, which opens
/// and closes as the columns change.
class _Missing extends StatelessWidget {
  const _Missing({required this.shown});

  final bool shown;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: BirkaMotion.reduced(context) ? Duration.zero : BirkaMotion.base,
      curve: BirkaMotion.standardCurve,
      alignment: Alignment.topCenter,
      child: !shown
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: BirkaTokens.spaceMd),
              child: Semantics(
                liveRegion: true,
                child: TintedNotice(
                  color: const Color(BirkaTokens.colorPaletteAmber),
                  text: t.imports.missing,
                ),
              ),
            ),
    );
  }
}

/// The first rows of the file as they will come into the ledger.
class _Preview extends StatelessWidget {
  const _Preview({required this.state});

  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final statement = state.statement!;
    final rows = statement.rows.take(ImportColumnsPage.shown).toList();
    final thisYear = statement.to?.year ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(t.imports.previewTitle),
        if (rows.isNotEmpty)
          Text(
            t.imports.previewNote(
              shown: rows.length,
              total: formatCount(statement.rows.length),
            ),
            style: styles.caption.copyWith(color: colors.textSubtle),
          ),
        const SizedBox(height: BirkaTokens.spaceXs),
        if (rows.isEmpty)
          Text(
            state.layout!.missing.isEmpty
                ? t.imports.noAmounts
                : t.imports.missing,
            style: styles.body.copyWith(color: colors.negative),
          )
        else
          GlassListGroup(
            children: [
              for (final row in rows)
                GlassListRow(
                  title: row.description.isEmpty ? '—' : row.description,
                  subtitle: dateLabel(
                    year: row.date.day.year,
                    month: row.date.day.month,
                    day: row.date.day.day,
                    thisYear: thisYear,
                  ),
                  trailing: _amount(row, styles),
                ),
            ],
          ),
      ],
    );
  }

  Widget _amount(StatementRow row, BirkaTextStyles styles) {
    final leg = row.out ?? row.into!;
    final value = row.isTransfer ? leg.amount : row.change;
    final money = moneyOf(value, leg.currency, fallback: state.currency);
    return AmountText(
      money == null
          ? '—'
          : money.isPositive && !row.isTransfer
          ? '+${formatMoney(money)}'
          : formatMoney(money),
      tone: money != null && money.isPositive && !row.isTransfer
          ? AmountTone.positive
          : AmountTone.neutral,
      style: styles.bodyStrong,
    );
  }
}

/// A quieter paragraph of the page.
class _Quiet extends StatelessWidget {
  const _Quiet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: BirkaTextStyles.of(
      context,
    ).body.copyWith(color: BirkaColors.of(context).textSecondary),
  );
}
