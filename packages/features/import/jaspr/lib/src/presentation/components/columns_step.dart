import 'package:design_jaspr/design_jaspr.dart';
import 'package:import_common/import_common.dart';
import 'package:import_jaspr/src/presentation/components/import_bits.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// The third step: what each column holds, how the values read, the first
/// rows as they enter the ledger, and the categories of the bank against
/// those of the ledger.
class ColumnsStep extends StatelessComponent {
  /// Creates the step of [state].
  const ColumnsStep({required this.state, super.key});

  /// The import.
  final ImportState state;

  /// How many rows the step shows.
  static const shown = 8;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<ImportCubit>();
    final layout = state.layout!;
    final statement = state.statement!;
    final options = layout.options;
    final problems = statement.problems;
    return div(classes: 'import-stack', [
      section(classes: 'import-section', [
        SectionLabel(t.imports.columnsTitle),
        div(classes: 'import-columns', [
          for (final column in layout.columns)
            if (column.header.trim().isNotEmpty || !column.sample.isBlank)
              _column(cubit, layout, column),
        ]),
      ]),
      div(classes: 'import-options', [
        _option(
          kind: 'sign',
          t.imports.signTitle,
          GlassSegmented<AmountSign>(
            segments: {
              for (final sign in AmountSign.values)
                sign: t.imports.signs[sign.name] ?? sign.name,
            },
            selected: options.sign,
            onChanged: (sign) => cubit.setOptions(options.copyWith(sign: sign)),
          ),
        ),
        _option(
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
        _option(
          kind: 'dates',
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
      ]),
      if (layout.missing.isNotEmpty) GlassNotice(text: t.imports.missing),
      if (problems.isNotEmpty)
        GlassNotice(
          title: t.imports.problems(
            n: problems.length,
            count: formatCount(problems.length),
          ),
          text: [
            for (final problem in problems.take(3))
              t.imports.problemLine(
                line: problem.line,
                fault: t.imports.rowFaults[problem.fault.name] ?? problem.text,
              ),
            if (problems.length > 3)
              t.imports.andMore(count: formatCount(problems.length - 3)),
          ].join('; '),
        ),
      if (statement.rows.isNotEmpty) _preview(statement),
      if (state.choices case final choices?
          when choices.categories.isNotEmpty || _hasFees(statement))
        _categories(cubit, choices, statement),
    ]);
  }

  Component _column(
    ImportCubit cubit,
    StatementLayout layout,
    StatementColumn column,
  ) {
    final role = layout.roles[column.index];
    final header = column.header.trim();
    final name = header.isEmpty ? '${column.index + 1}' : header;
    return div(classes: 'glass import-column', [
      span(classes: 'text-body-strong import-column__name', [.text(name)]),
      span(classes: 'text-caption import-column__sample', [
        .text(column.sample.isBlank ? '—' : column.sample.text.trim()),
      ]),
      BirkaSelect<ColumnRole>(
        label: t.imports.roleOf(header: name),
        options: {
          for (final role in ColumnRole.values)
            role: t.imports.roles[role.name] ?? role.name,
        },
        selected: role,
        quiet: role == ColumnRole.skip,
        onChanged: (role) => cubit.setRole(column.index, role),
      ),
    ]);
  }

  Component _option(String label, Component control, {String? kind}) {
    return div(
      classes: kind == null
          ? 'import-option'
          : 'import-option import-option--$kind',
      [
        span(classes: 'text-caption import-option__label', [.text(label)]),
        control,
      ],
    );
  }

  Component _preview(Statement statement) {
    final rows = statement.rows.take(shown).toList();
    final thisYear = statement.to?.year ?? 0;
    return section(classes: 'import-section', [
      div(classes: 'import-section__head', [
        SectionLabel(t.imports.previewTitle),
        span(classes: 'text-caption import-section__note', [
          .text(
            t.imports.previewNote(
              shown: rows.length,
              total: formatCount(statement.rows.length),
            ),
          ),
        ]),
      ]),
      div(classes: 'glass import-table', [
        div(classes: 'text-label import-table__head', [
          span([.text(t.imports.previewDate)]),
          span([.text(t.imports.previewText)]),
          span([.text(t.imports.previewCategory)]),
          span(classes: 'import-table__amount', [
            .text(t.imports.previewAmount),
          ]),
        ]),
        for (final row in rows) _row(row, thisYear),
      ]),
    ]);
  }

  Component _row(StatementRow row, int thisYear) {
    final leg = row.out ?? row.into!;
    final value = row.isTransfer ? leg.amount : row.change;
    final money = moneyOf(value, leg.currency, fallback: state.currency);
    final (label, color) = _categoryOf(row);
    return div(classes: 'import-table__row', [
      span(classes: 'text-body import-table__date', [
        .text(dayLabel(row.date.day, thisYear: thisYear)),
      ]),
      span(classes: 'import-table__text', [
        span(classes: 'text-body-strong import-table__description', [
          .text(row.description.isEmpty ? '—' : row.description),
        ]),
        if (row.note.isNotEmpty)
          span(classes: 'text-caption import-table__note', [.text(row.note)]),
      ]),
      span(classes: 'text-body import-table__category', [
        span(
          classes: 'import-table__dot',
          styles: Styles(raw: {'background': color}),
          const [],
        ),
        .text(label),
      ]),
      span(classes: 'import-table__amount', [
        if (money == null)
          AmountText(value.toString(), textClass: 'text-body-strong')
        else
          AmountText(
            row.isTransfer ? formatMoney(money) : signedMoney(money),
            tone: row.isTransfer ? AmountTone.neutral : toneOf(money),
            textClass: 'text-body-strong',
          ),
      ]),
    ]);
  }

  /// What category a row goes into, and its color.
  (String, String) _categoryOf(StatementRow row) {
    if (row.isTransfer) return (t.imports.transfer, 'var(--color-palette-sky)');
    final bank = (
      kind: row.out != null ? CategoryKind.expense : CategoryKind.income,
      name: row.category,
    );
    return switch (state.choices?.categories[bank]) {
      IntoCategory(:final categoryId) => switch (_category(categoryId)) {
        final category? => (
          category.name,
          category.color ?? 'var(--color-text-subtle)',
        ),
        null => (t.app.noCategory, 'var(--color-text-subtle)'),
      },
      NewCategory(:final name) => (name, 'var(--color-accent)'),
      _ => (t.app.noCategory, 'var(--color-text-subtle)'),
    };
  }

  Category? _category(String id) =>
      state.categories.where((it) => it.id == id).firstOrNull;

  static bool _hasFees(Statement statement) =>
      statement.rows.any((row) => row.fee != null);

  Component _categories(
    ImportCubit cubit,
    ImportChoices choices,
    Statement statement,
  ) {
    final kinds = <String?, Set<CategoryKind>>{};
    for (final bank in choices.categories.keys) {
      (kinds[bank.name] ??= {}).add(bank.kind);
    }
    return section(classes: 'import-section', [
      div(classes: 'import-section__head', [
        SectionLabel(t.imports.categoriesTitle),
        span(classes: 'text-caption import-section__note', [
          .text(t.imports.categoriesNote),
        ]),
      ]),
      div(classes: 'import-categories', [
        for (final MapEntry(key: bank, value: choice)
            in choices.categories.entries)
          _categoryRow(
            label: [
              bank.name ?? t.imports.noBankCategory,
              if (kinds[bank.name]!.length > 1)
                t.imports.categoryKinds[bank.kind.name] ?? bank.kind.name,
            ].join(' · '),
            kind: bank.kind,
            choice: choice,
            newName: bank.name,
            onChanged: (choice) => cubit.chooseCategory(bank, choice),
          ),
        if (_hasFees(statement))
          _categoryRow(
            label: t.imports.fees,
            kind: CategoryKind.expense,
            choice: choices.fees,
            newName: t.imports.fees,
            onChanged: cubit.chooseFees,
          ),
      ]),
    ]);
  }

  Component _categoryRow({
    required String label,
    required CategoryKind kind,
    required CategoryChoice choice,
    required String? newName,
    required ValueChanged<CategoryChoice> onChanged,
  }) {
    const inbox = 'inbox';
    const fresh = 'new';
    final created = switch (choice) {
      final NewCategory category => category,
      _ when newName != null => NewCategory(newName),
      _ => null,
    };
    final ours = categoryTree(state.categories, kind);
    final selected = switch (choice) {
      IntoCategory(:final categoryId) => 'id:$categoryId',
      NewCategory() => fresh,
      Unsorted() => inbox,
    };
    final picked = switch (choice) {
      IntoCategory(:final categoryId) => _category(categoryId),
      _ => null,
    };
    return div(classes: 'glass import-category', [
      span(classes: 'text-body import-category__bank', [.text(label)]),
      const span(classes: 'text-body import-category__arrow', [.text('→')]),
      BirkaSelect<String>(
        label: t.imports.categoryOf(name: label),
        pill: true,
        options: {
          inbox: t.imports.inbox,
          for (final (:category, nested: _) in ours)
            'id:${category.id}': category.name,
          if (created != null) fresh: t.imports.newCategory(name: created.name),
        },
        selected: selected,
        nested: {
          for (final (:category, :nested) in ours)
            if (nested) 'id:${category.id}',
        },
        dot: switch (choice) {
          Unsorted() => 'var(--color-text-subtle)',
          NewCategory() => 'var(--color-accent)',
          IntoCategory() => picked?.color ?? 'var(--color-text-subtle)',
        },
        quiet: choice is Unsorted,
        onChanged: (key) {
          if (key == inbox) {
            onChanged(const Unsorted());
          } else if (key == fresh && created != null) {
            onChanged(created);
          } else if (key.startsWith('id:')) {
            onChanged(IntoCategory(key.substring(3)));
          }
        },
      ),
    ]);
  }

  /// The styles of the step.
  @css
  static List<StyleRule> get styles => [
    css('.import-columns').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'repeat(auto-fill, minmax(200px, 1fr))',
      },
    ),
    css('.import-column').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
        'padding': 'var(--space-sm)',
      },
    ),
    css('.import-column__name').styles(
      raw: {
        'color': 'var(--color-text)',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.import-column__sample').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'margin-bottom': 'var(--space-xs)',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.import-options').styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.import-option').styles(
      raw: {
        'display': 'flex',
        'flex': '1 1 170px',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'min-width': '0',
      },
    ),
    // Three ways of a sign need the room of two, and the dates are long.
    css('.import-option--sign').styles(raw: {'flex': '2 1 300px'}),
    css('.import-option--dates').styles(raw: {'flex': '1 1 200px'}),
    css('.import-option__label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.import-table').styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'padding': '0'},
    ),
    css('.import-table__head, .import-table__row').styles(
      raw: {
        'align-items': 'center',
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': '96px minmax(0, 1fr) minmax(0, 0.8fr) auto',
        'padding': 'var(--space-sm) var(--space-md)',
      },
    ),
    css('.import-table__head').styles(
      raw: {'color': 'var(--color-text-subtle)'},
    ),
    css('.import-table__row').styles(
      raw: {'border-top': '1px solid var(--color-hairline)'},
    ),
    css('.import-table__date').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.import-table__text').styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'min-width': '0'},
    ),
    css('.import-table__description, .import-table__note').styles(
      raw: {
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.import-table__description').styles(
      raw: {'color': 'var(--color-text)'},
    ),
    css('.import-table__note').styles(
      raw: {'color': 'var(--color-text-subtle)'},
    ),
    css('.import-table__category').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text)',
        'display': 'flex',
        'gap': 'var(--space-xs)',
        'min-width': '0',
      },
    ),
    css('.import-table__dot').styles(
      raw: {
        'border-radius': '50%',
        'flex': 'none',
        'height': '8px',
        'width': '8px',
      },
    ),
    css('.import-table__amount').styles(raw: {'text-align': 'end'}),
    // A phone keeps the date and the amount by the description, and puts the
    // category under it.
    css.media(const MediaQuery.raw('(max-width: 640px)'), [
      css('.import-table__head').styles(raw: {'display': 'none'}),
      css('.import-table__row').styles(
        raw: {'grid-template-columns': 'minmax(0, 1fr) auto'},
      ),
      css('.import-table__date').styles(
        raw: {'grid-column': '1 / -1', 'order': '-1'},
      ),
      css('.import-table__category').styles(raw: {'grid-column': '1 / -1'}),
    ]),
    css('.import-categories').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'repeat(auto-fit, minmax(280px, 1fr))',
      },
    ),
    css('.import-category').styles(
      raw: {
        'align-items': 'center',
        'display': 'grid',
        'gap': 'var(--space-sm)',
        // The name of the bank stays whole first; our side gives way.
        'grid-template-columns':
            'minmax(0, max-content) auto minmax(140px, 1fr)',
        'min-width': '0',
        'padding':
            'var(--space-xs) var(--space-xs) var(--space-xs) '
            'var(--space-md)',
      },
    ),
    css('.import-category__bank').styles(
      raw: {
        'color': 'var(--color-text)',
        'min-width': '0',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.import-category__arrow').styles(
      raw: {'color': 'var(--color-text-subtle)'},
    ),
    css('.import-category .birka-select').styles(
      raw: {'justify-self': 'end'},
    ),
    // A phone puts our category under the one of the bank.
    css.media(const MediaQuery.raw('(max-width: 640px)'), [
      css('.import-category').styles(
        raw: {
          'grid-template-columns': 'minmax(0, 1fr)',
          'padding': 'var(--space-sm)',
        },
      ),
      css('.import-category__arrow').styles(raw: {'display': 'none'}),
      css('.import-category .birka-select').styles(
        raw: {'justify-self': 'stretch'},
      ),
    ]),
  ];
}
