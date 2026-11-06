import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:import_common/import_common.dart';
import 'package:import_flutter/src/presentation/widgets/format_mark.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// The categories of the bank of a statement on the phone, as their board
/// draws them: the expenses and the income apart, each category with how
/// many operations carry it and where they go, which a tap on it changes.
/// It needs an [ImportCubit] above it.
class ImportCategoriesPage extends StatelessWidget {
  /// Creates the page.
  const ImportCategoriesPage({super.key});

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
              final choices = state.choices;
              final plan = state.plan;
              if (choices == null || plan == null) {
                return const SizedBox.shrink();
              }
              final format = state.layout?.format;
              final waiting = plan.unsorted;
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
                      label: t.imports.categoriesHeading,
                      backLabel: t.imports.back,
                      onBack: () => Navigator.of(context).pop(),
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
                          _File(state: state),
                          const SizedBox(height: BirkaTokens.spaceMd),
                          Text(
                            categoriesIntro(state),
                            style: BirkaTextStyles.of(context).body.copyWith(
                              color: BirkaColors.of(context).textSecondary,
                            ),
                          ),
                          for (final kind in CategoryKind.values)
                            if (choices.categories.keys.any(
                                  (it) => it.kind == kind,
                                ) ||
                                (kind == CategoryKind.expense &&
                                    plan.withFees > 0))
                              _Kind(kind: kind, state: state),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BirkaButton(
                          label: waiting > 0
                              ? t.imports.categoriesDone(
                                  count: formatCount(waiting),
                                )
                              : t.imports.finish,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: BirkaTokens.spaceXs),
                        Text(
                          categoriesKept(format),
                          textAlign: TextAlign.center,
                          style: BirkaTextStyles.of(context).caption.copyWith(
                            color: BirkaColors.of(context).textSubtle,
                          ),
                        ),
                      ],
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

/// The file the categories come from, with how many it has.
class _File extends StatelessWidget {
  const _File({required this.state});

  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final format = state.layout?.format;
    final total = state.choices!.categories.length;
    return GlassFileCard(
      mark: format == null
          ? GlyphBadge(
              glyph: BirkaGlyph.file,
              color: BirkaColors.of(context).accent,
            )
          : FormatMark(format),
      name: state.fileName ?? '',
      line: [
        if (format == null) t.imports.own else formatLabel(format),
        t.imports.categoriesCount(n: total, count: formatCount(total)),
      ].join(' · '),
    );
  }
}

/// The categories of the bank of one kind, with the fees among the expenses.
class _Kind extends StatelessWidget {
  const _Kind({required this.kind, required this.state});

  final CategoryKind kind;
  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final cubit = context.read<ImportCubit>();
    final choices = state.choices!;
    final plan = state.plan!;
    final uses = plan.categoryUses;
    final banks = [
      for (final bank in choices.categories.keys)
        if (bank.kind == kind) bank,
    ];
    final fees = kind == CategoryKind.expense ? plan.withFees : 0;
    final count = banks.fold(0, (sum, bank) => sum + (uses[bank] ?? 0));
    return Padding(
      padding: const EdgeInsets.only(top: BirkaTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionLabel(
                  kind == CategoryKind.expense
                      ? t.imports.summarySpent
                      : t.imports.summaryReceived,
                ),
              ),
              Text(
                operationsLabel(count),
                style: styles.caption.copyWith(color: colors.textSubtle),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          GlassListGroup(
            children: [
              for (final bank in banks)
                _row(
                  context,
                  name: bank.name ?? t.imports.noBankCategory,
                  kind: kind,
                  uses: uses[bank] ?? 0,
                  choice: choices.categories[bank]!,
                  newName: bank.name,
                  onChanged: (choice) => cubit.chooseCategory(bank, choice),
                ),
              if (fees > 0)
                _row(
                  context,
                  name: t.imports.fees,
                  kind: kind,
                  uses: fees,
                  choice: choices.fees,
                  newName: t.imports.fees,
                  onChanged: cubit.chooseFees,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String name,
    required CategoryKind kind,
    required int uses,
    required CategoryChoice choice,
    required String? newName,
    required ValueChanged<CategoryChoice> onChanged,
  }) {
    return GlassListRow(
      title: name,
      subtitle: [
        operationsLabel(uses),
        if (choice is NewCategory) t.imports.newCategoryMark,
      ].join(' · '),
      subtitleLines: 2,
      trailing: GlassListValue(_labelOf(choice)),
      onTap: () => unawaited(
        _choose(
          context,
          name: name,
          kind: kind,
          uses: uses,
          choice: choice,
          newName: newName,
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Where [choice] sends the operations, for people.
  String _labelOf(CategoryChoice choice) => switch (choice) {
    IntoCategory(:final categoryId) =>
      state.categories.where((it) => it.id == categoryId).firstOrNull?.name ??
          t.app.noCategory,
    NewCategory(:final name) => name,
    Unsorted() => t.imports.inbox,
  };

  /// Lets the person send the operations of the category [name] of the bank
  /// to the inbox, into a category of [kind] that the ledger has, or into a
  /// new one named [newName].
  Future<void> _choose(
    BuildContext context, {
    required String name,
    required CategoryKind kind,
    required int uses,
    required CategoryChoice choice,
    required String? newName,
    required ValueChanged<CategoryChoice> onChanged,
  }) async {
    final colors = BirkaColors.of(context);
    final tree = categoryTree(state.categories, kind);
    final byId = {
      for (final (:category, nested: _) in tree) 'id:${category.id}': category,
    };
    final nested = {
      for (final (:category, :nested) in tree)
        if (nested) 'id:${category.id}',
    };
    final created = switch (choice) {
      final NewCategory made => made,
      _
          when newName != null &&
              !byId.values.any((it) => sameName(it.name, newName)) =>
        NewCategory(newName),
      _ => null,
    };
    Widget mark(Widget child, {bool inside = false}) => Padding(
      padding: EdgeInsetsDirectional.only(
        start: inside ? BirkaTokens.spaceMd : 0,
      ),
      child: SizedBox(width: 20, child: Center(child: child)),
    );
    final picked = await showChoiceSheet<String>(
      context,
      title: t.imports.categoryOf(name: name),
      subtitle: [
        operationsLabel(uses),
        t.imports.categoryKinds[kind.name] ?? kind.name,
      ].join(' · '),
      choices: [_inbox, ...byId.keys, if (created != null) _new],
      selected: switch (choice) {
        IntoCategory(:final categoryId) => 'id:$categoryId',
        NewCategory() => _new,
        Unsorted() => _inbox,
      },
      labelOf: (key) => switch (key) {
        _inbox => t.imports.inbox,
        _new => t.imports.newCategory(name: created!.name),
        _ => byId[key]!.name,
      },
      subtitleOf: (key) => switch (key) {
        _inbox => t.imports.inboxNote,
        _new => t.imports.newCategoryNote,
        _ => null,
      },
      leadingOf: (key) => switch (key) {
        _inbox => mark(
          const BirkaIcon(
            BirkaGlyph.inbox,
            size: 18,
            color: Color(BirkaTokens.colorPaletteAmber),
          ),
        ),
        _new => mark(
          BirkaIcon(BirkaGlyph.plus, size: 16, color: colors.accent),
        ),
        _ => mark(
          CategoryDot(byId[key]!.color),
          inside: nested.contains(key),
        ),
      },
      accentOf: (key) => key == _new,
    );
    if (picked == null) return;
    onChanged(switch (picked.$1) {
      _inbox => const Unsorted(),
      _new => created!,
      final key => IntoCategory(byId[key]!.id),
    });
  }

  static const _inbox = 'inbox';
  static const _new = 'new';
}
