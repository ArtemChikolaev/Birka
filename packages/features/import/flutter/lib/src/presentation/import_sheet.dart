import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:import_common/import_common.dart';
import 'package:import_flutter/src/presentation/import_categories_page.dart';
import 'package:import_flutter/src/presentation/import_columns_page.dart';
import 'package:import_flutter/src/presentation/widgets/format_mark.dart';
import 'package:import_flutter/src/presentation/widgets/left_rows_sheet.dart';
import 'package:import_flutter/src/presentation/widgets/table_card.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// Lets the person choose a statement through [files] and imports it in a
/// sheet from the bottom of the screen, as the board of the phone draws it
/// (ADR 0021). [cubit] makes the import, which closes with the sheet; what
/// waits in the inbox after it leads to [onInbox], when the host has one.
Future<void> showImportSheet(
  BuildContext context, {
  required ImportCubit Function() cubit,
  required StatementFiles files,
  VoidCallback? onInbox,
}) async {
  final file = await files.choose();
  if (file == null || !context.mounted) return;
  final importing = cubit();
  unawaited(_read(importing, file));
  bool? toInbox;
  try {
    toInbox = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: BirkaColors.of(context).background,
      builder: (context) => BlocProvider.value(
        value: importing,
        child: ImportSheet(
          fileName: file.name,
          files: files,
          toInbox: onInbox != null,
        ),
      ),
    );
  } finally {
    // The way on does not wait for the import to let go of the ledger.
    unawaited(importing.close());
  }
  if (toInbox ?? false) onInbox?.call();
}

/// Reads what the ledger offers to choose from, then [file].
Future<void> _read(ImportCubit cubit, ChosenStatement file) async {
  await cubit.start();
  if (!cubit.isClosed) await cubit.read(file.name, file.bytes);
}

/// The keys of the choices of an account that are no account of the ledger.
const _created = '+';
const _left = '-';

/// What the sheet shows of the import.
enum _Stage {
  /// The file is being read, or the import planned.
  reading,

  /// The file holds no operations to read.
  unreadable,

  /// The columns are of no format that Birka knows, or lack the date or
  /// the amount, until the person sets them.
  unknown,

  /// More rows did not read than did, so the columns are likely read
  /// wrong, as when a bank changes its statement.
  unread,

  /// What Birka recognized, where it goes and what comes in.
  ready,

  /// What came in, with its undo.
  done,

  /// The import taken back out.
  undone
  ;

  /// The stage of [state]; the columns of a format of one's own count once
  /// the person has [set] them.
  static _Stage of(ImportState state, {required bool set}) {
    if (state.undone) return undone;
    if (state.importId != null) return done;
    if (state.unreadable != null) return unreadable;
    final layout = state.layout;
    if (state.reading || layout == null) return reading;
    final own = layout.format == null;
    if (layout.missing.isNotEmpty || own && (!set || !state.readable)) {
      return unknown;
    }
    if (state.statement case final statement? when mostlyUnread(statement)) {
      return unread;
    }
    if (!state.readable) return unreadable;
    return state.planned ? ready : reading;
  }
}

/// The import of one statement in a sheet, as the board of the phone draws
/// it: the file being read, what Birka recognized in it and where it goes,
/// a format it does not know with the way to its columns, and what came in
/// with its undo. It needs an [ImportCubit] above it.
class ImportSheet extends StatefulWidget {
  /// Creates the sheet of the file [fileName], which [files] can change.
  const ImportSheet({
    required this.fileName,
    required this.files,
    this.toInbox = false,
    super.key,
  });

  /// The name of the file chosen first, said before its table is read.
  final String fileName;

  /// The window that chooses another file.
  final StatementFiles files;

  /// Whether what waits in the inbox leads there, which closes the sheet
  /// with `true`.
  final bool toInbox;

  @override
  State<ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<ImportSheet> {
  late String _fileName = widget.fileName;

  /// Whether the person set the columns of a format of their own.
  bool _columnsSet = false;

  Future<void> _chooseAnother(ImportCubit cubit) async {
    final file = await widget.files.choose();
    if (file == null || !mounted) return;
    setState(() {
      _fileName = file.name;
      _columnsSet = false;
    });
    await cubit.read(file.name, file.bytes);
  }

  Future<void> _setColumns(ImportCubit cubit) async {
    final set = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const ImportColumnsPage(),
        ),
      ),
    );
    if ((set ?? false) && mounted) setState(() => _columnsSet = true);
  }

  Future<void> _setCategories(ImportCubit cubit) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const ImportCategoriesPage(),
      ),
    ),
  );

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final reduced = BirkaMotion.reduced(context);
    return BlocBuilder<ImportCubit, ImportState>(
      builder: (context, state) {
        final cubit = context.read<ImportCubit>();
        final colors = BirkaColors.of(context);
        final styles = BirkaTextStyles.of(context);
        final stage = _Stage.of(state, set: _columnsSet);
        return PopScope(
          canPop: !state.writing,
          child: AnimatedSize(
            duration: reduced ? Duration.zero : BirkaMotion.base,
            curve: BirkaMotion.standardCurve,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: reduced ? Duration.zero : BirkaMotion.fast,
              switchInCurve: BirkaMotion.fadeCurve,
              switchOutCurve: BirkaMotion.fadeCurve,
              child: ChoiceSheet(
                key: ValueKey(stage),
                title: switch (stage) {
                  _Stage.reading => t.imports.readingTitle,
                  _Stage.unreadable => t.imports.unreadableTitle,
                  _Stage.unknown => t.imports.unknownTitle,
                  _Stage.unread || _Stage.ready => t.imports.title,
                  _Stage.done => null,
                  _Stage.undone => t.imports.undoneTitle,
                },
                children: [
                  if (state.failed) ...[
                    Text(
                      t.imports.failed,
                      style: styles.body.copyWith(color: colors.negative),
                    ),
                    const SizedBox(height: BirkaTokens.spaceMd),
                  ],
                  ...switch (stage) {
                    _Stage.reading => _reading(context),
                    _Stage.unreadable => _unreadable(context, cubit, state),
                    _Stage.unknown => _unknown(context, cubit, state),
                    _Stage.unread => _unread(context, cubit, state),
                    _Stage.ready => _ready(context, cubit, state),
                    _Stage.done => _done(context, cubit, state),
                    _Stage.undone => _undone(context),
                  },
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _reading(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return [
      Text(
        _fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: styles.body.copyWith(color: colors.textSecondary),
      ),
      const SizedBox(height: BirkaTokens.spaceMd),
      ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(BirkaTokens.radiusXs),
        ),
        child: LinearProgressIndicator(
          minHeight: 8,
          color: colors.accent,
          backgroundColor: colors.surface,
          semanticsLabel: t.imports.reading,
        ),
      ),
      const SizedBox(height: BirkaTokens.spaceMd),
      Text(
        t.imports.readingNote,
        style: styles.caption.copyWith(color: colors.textSubtle),
      ),
    ];
  }

  List<Widget> _unreadable(
    BuildContext context,
    ImportCubit cubit,
    ImportState state,
  ) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final reason = state.unreadable ?? UnreadableReason.empty;
    return [
      Text(
        t.imports.unreadable[reason.name] ?? t.imports.failed,
        style: styles.body.copyWith(color: colors.textSecondary),
      ),
      const SizedBox(height: BirkaTokens.spaceLg),
      ..._another(cubit),
    ];
  }

  List<Widget> _unknown(
    BuildContext context,
    ImportCubit cubit,
    ImportState state,
  ) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return [
      TableCard(table: state.table!),
      const SizedBox(height: BirkaTokens.spaceMd),
      Text(
        t.imports.unknownText,
        style: styles.body.copyWith(color: colors.textSecondary),
      ),
      const SizedBox(height: BirkaTokens.spaceLg),
      BirkaButton(
        label: t.imports.assignColumns,
        onPressed: () => unawaited(_setColumns(cubit)),
      ),
      const SizedBox(height: BirkaTokens.spaceXs),
      BirkaButton(label: t.imports.cancel, quiet: true, onPressed: _close),
    ];
  }

  List<Widget> _unread(
    BuildContext context,
    ImportCubit cubit,
    ImportState state,
  ) {
    final statement = state.statement!;
    final unread = unreadRows(statement).length;
    final total = statement.rows.length + statement.problems.length;
    return [
      _fileCard(context, state),
      const SizedBox(height: BirkaTokens.spaceSm),
      TintedNotice(
        color: BirkaColors.of(context).negative,
        glyph: BirkaGlyph.alert,
        title: t.imports.mostUnread(
          n: unread,
          count: formatCount(unread),
          total: formatCount(total),
        ),
        text: t.imports.mostUnreadText,
      ),
      const SizedBox(height: BirkaTokens.spaceLg),
      BirkaButton(
        label: t.imports.checkColumns,
        onPressed: () => unawaited(_setColumns(cubit)),
      ),
      const SizedBox(height: BirkaTokens.spaceXs),
      BirkaButton(label: t.imports.cancel, quiet: true, onPressed: _close),
    ];
  }

  /// The file and how Birka read it.
  Widget _fileCard(BuildContext context, ImportState state) {
    final format = state.layout!.format;
    return GlassFileCard(
      mark: format == null
          ? GlyphBadge(
              glyph: BirkaGlyph.file,
              color: BirkaColors.of(context).accent,
            )
          : FormatMark(format),
      name: state.fileName ?? _fileName,
      line: format == null
          ? '${t.imports.own} · ${t.imports.ownColumns}'
          : t.imports.knownBy(bank: formatLabel(format)),
    );
  }

  /// The way to another file, and out.
  List<Widget> _another(ImportCubit cubit) => [
    BirkaButton(
      label: t.imports.chooseAnother,
      onPressed: () => unawaited(_chooseAnother(cubit)),
    ),
    const SizedBox(height: BirkaTokens.spaceXs),
    BirkaButton(label: t.imports.cancel, quiet: true, onPressed: _close),
  ];

  List<Widget> _ready(
    BuildContext context,
    ImportCubit cubit,
    ImportState state,
  ) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final statement = state.statement!;
    final plan = state.plan!;
    final choices = plan.choices.accounts;
    final added = plan.added.length;
    final copies = plan.copies.length;
    final from = statement.from;
    final to = statement.to;
    final progress = state.progress;
    final several = statement.accounts.length > 1;
    final unread = unreadRows(statement).length;
    final declined = declinedRows(statement).length;
    final unfit = plan.problems.length;
    final left = unread + declined + unfit;
    const amber = Color(BirkaTokens.colorPaletteAmber);
    // Outside the list below: the analyzer of Dart 3.10 fails on a
    // null-aware element in a list that also uses the context.
    String balanceOf(SourceAccount source) => [
      t.imports.summaryBalance,
      if (several) ?_nameOf(choices[source.key]),
    ].join(' · ');
    return [
      _fileCard(context, state),
      const SizedBox(height: BirkaTokens.spaceSm),
      GlassListGroup(
        children: [
          for (final source in statement.accounts)
            _account(context, cubit, state, source, choices[source.key]),
        ],
      ),
      if (plan.choices.categories.isNotEmpty || plan.withFees > 0) ...[
        const SizedBox(height: BirkaTokens.spaceSm),
        GlassListGroup(
          children: [
            GlassListRow(
              title: t.imports.categoriesHeading,
              subtitle: categoriesLine(state),
              leading: GlyphBadge(
                glyph: BirkaGlyph.list,
                color: colors.textMuted,
              ),
              trailing: BirkaIcon(
                BirkaGlyph.chevron,
                size: 18,
                color: colors.textSubtle,
              ),
              onTap: state.writing
                  ? null
                  : () => unawaited(_setCategories(cubit)),
            ),
          ],
        ),
      ],
      if (left > 0) ...[
        const SizedBox(height: BirkaTokens.spaceSm),
        GlassListGroup(
          children: [
            GlassListRow(
              title: t.imports.rowsLeft(n: left, count: formatCount(left)),
              subtitle: leftLine(
                unread: unread,
                declined: declined,
                unfit: unfit,
              ),
              subtitleLines: 2,
              leading: const GlyphBadge(glyph: BirkaGlyph.alert, color: amber),
              trailing: BirkaIcon(
                BirkaGlyph.chevron,
                size: 18,
                color: colors.textSubtle,
              ),
              onTap: () => unawaited(showLeftRows(context, state)),
            ),
          ],
        ),
      ],
      const SizedBox(height: BirkaTokens.spaceMd),
      _Line(
        label: from == null || to == null
            ? t.imports.summaryOperations
            : t.imports.operationsIn(period: periodLabel(from, to)),
        value: Text(formatCount(statement.rows.length)),
      ),
      if (copies > 0)
        _Line(
          label: t.imports.alreadyIn,
          value: Text(t.imports.willSkip(count: formatCount(copies))),
        ),
      if (plan.unsorted > 0)
        _Line(
          label: t.imports.sortLater,
          value: Text(t.imports.inInbox(count: formatCount(plan.unsorted))),
        ),
      for (final source in statement.accounts)
        if (plan.balances[source.key] case final after?) ...[
          _Line(
            label: balanceOf(source),
            value: AmountText(
              formatMoney(after),
              style: styles.bodyStrong.copyWith(color: colors.text),
            ),
            matches: switch (bankBalance(source, after)) {
              null => null,
              final bank => bank == after,
            },
          ),
          if (bankBalance(source, after) case final bank? when bank != after)
            Text(
              (unread > 0 ? t.imports.bankHasMissing : t.imports.bankHas)(
                amount: HiddenAmounts.mask(context, formatMoney(bank)),
              ),
              style: styles.caption.copyWith(color: amber),
            ),
        ],
      const SizedBox(height: BirkaTokens.spaceLg),
      BirkaButton(
        label: progress != null
            ? t.imports.writing(
                done: formatCount(progress.done),
                total: formatCount(progress.total),
              )
            : added == 0
            ? t.imports.nothingToWrite
            : t.imports.write(n: added, count: formatCount(added)),
        onPressed: state.writing || added == 0
            ? null
            : () => unawaited(cubit.write()),
      ),
      const SizedBox(height: BirkaTokens.spaceXs),
      BirkaButton(
        label: t.imports.cancel,
        quiet: true,
        onPressed: state.writing ? null : _close,
      ),
    ];
  }

  /// Where the operations of [source] go, which a tap changes.
  Widget _account(
    BuildContext context,
    ImportCubit cubit,
    ImportState state,
    SourceAccount source,
    AccountChoice? choice,
  ) {
    final colors = BirkaColors.of(context);
    final onTap = state.writing
        ? null
        : () => unawaited(_pickAccount(context, cubit, state, source));
    final chevron = BirkaIcon(
      BirkaGlyph.chevron,
      size: 18,
      color: colors.textSubtle,
    );
    return switch (choice) {
      IntoAccount(:final account) => GlassListRow(
        title: account.name,
        subtitle: _lineOf(account, source),
        leading: CardArtThumbnail(art: CardArt.values.byName(account.art.name)),
        trailing: chevron,
        onTap: onTap,
      ),
      NewAccount(:final name) => GlassListRow(
        title: name,
        subtitle: t.imports.newAccount,
        leading: GlyphBadge(glyph: BirkaGlyph.plus, color: colors.accent),
        trailing: chevron,
        onTap: onTap,
      ),
      _ => GlassListRow(
        title: _newNameOf(state, source),
        subtitle: t.imports.leaveOut,
        leading: GlyphBadge(glyph: BirkaGlyph.close, color: colors.textMuted),
        trailing: chevron,
        onTap: onTap,
      ),
    };
  }

  /// Lets the person send the operations of [source] into an open account
  /// of its currency, a new one, or nowhere.
  Future<void> _pickAccount(
    BuildContext context,
    ImportCubit cubit,
    ImportState state,
    SourceAccount source,
  ) async {
    final code = source.currency ?? state.currency.code;
    final accounts = {
      for (final account in state.accounts)
        if (!account.archived && account.openingBalance.currency.code == code)
          account.id: account,
    };
    final fresh = defaultAccount(
      source,
      const [],
      newName: _newNameOf(state, source),
      fallback: state.currency,
    );
    final picked = await showChoiceSheet<String>(
      context,
      title: sourceTitle(source),
      choices: [...accounts.keys, _created, _left],
      selected: switch (state.choices?.accounts[source.key]) {
        IntoAccount(:final account) => account.id,
        NewAccount() => _created,
        _ => _left,
      },
      labelOf: (key) => switch (key) {
        _created => t.imports.newAccount,
        _left => t.imports.leaveOut,
        _ => accounts[key]!.name,
      },
      subtitleOf: (key) => switch (key) {
        _created when fresh is NewAccount => t.imports.newAccountText(
          name: fresh.name,
          balance: HiddenAmounts.mask(
            context,
            formatMoney(fresh.openingBalance),
          ),
        ),
        _created => null,
        _left => t.imports.leaveOutText,
        _ => _lineOf(accounts[key]!, source),
      },
      leadingOf: (key) => switch (accounts[key]) {
        final account? => CardArtThumbnail(
          art: CardArt.values.byName(account.art.name),
        ),
        null => null,
      },
    );
    if (picked == null) return;
    cubit.chooseAccount(source.key, switch (picked.$1) {
      _created => fresh,
      _left => const LeaveOut(),
      final id => IntoAccount(accounts[id]!),
    });
  }

  List<Widget> _done(
    BuildContext context,
    ImportCubit cubit,
    ImportState state,
  ) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final plan = state.plan!;
    final statement = state.statement!;
    final format = state.layout?.format;
    final added = plan.added.length;
    final from = statement.from;
    final to = statement.to;
    final names = {
      for (final choice in plan.choices.accounts.values) ?_nameOf(choice),
    };
    return [
      Row(
        children: [
          const _DoneMark(),
          const SizedBox(width: BirkaTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.imports.doneTitle(n: added, count: formatCount(added)),
                  style: styles.heading.copyWith(color: colors.text),
                ),
                if (from != null && to != null)
                  Text(
                    t.imports.doneWhere(
                      format: format == null
                          ? state.fileName ?? _fileName
                          : formatLabel(format),
                      period: periodLabel(from, to),
                      accounts: names.join(', '),
                    ),
                    style: styles.caption.copyWith(color: colors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
      if (plan.unsorted > 0) ...[
        const SizedBox(height: BirkaTokens.spaceMd),
        Semantics(
          button: widget.toInbox,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.toInbox
                ? () => Navigator.of(context).pop(true)
                : null,
            child: GlassSurface(
              child: Row(
                children: [
                  const GlyphBadge(
                    glyph: BirkaGlyph.list,
                    color: Color(BirkaTokens.colorPaletteAmber),
                  ),
                  const SizedBox(width: BirkaTokens.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.imports.unsortedTitle(
                            n: plan.unsorted,
                            count: formatCount(plan.unsorted),
                          ),
                          style: styles.bodyStrong.copyWith(
                            color: colors.text,
                          ),
                        ),
                        Text(
                          t.imports.unsortedText,
                          style: styles.caption.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.toInbox)
                    BirkaIcon(
                      BirkaGlyph.chevron,
                      size: 18,
                      color: colors.textSubtle,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
      const SizedBox(height: BirkaTokens.spaceLg),
      BirkaButton(label: t.imports.finish, onPressed: _close),
      const SizedBox(height: BirkaTokens.spaceXs),
      BirkaButton(
        label: t.imports.undoImport,
        quiet: true,
        danger: true,
        onPressed: () => unawaited(cubit.undo()),
      ),
    ];
  }

  List<Widget> _undone(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return [
      Text(
        t.imports.undoneText,
        style: styles.body.copyWith(color: colors.textSecondary),
      ),
      const SizedBox(height: BirkaTokens.spaceLg),
      BirkaButton(label: t.imports.finish, onPressed: _close),
    ];
  }
}

/// The name of the account that [choice] sends operations into.
String? _nameOf(AccountChoice? choice) => switch (choice) {
  IntoAccount(:final account) => account.name,
  NewAccount(:final name) => name,
  _ => null,
};

/// The name of a new account for [source], such as «Альфа-Банк ••4821».
String _newNameOf(ImportState state, SourceAccount source) =>
    newAccountNames(
      state.statement!.accounts,
      state.layout?.format,
    )[source.key] ??
    source.key;

/// What ties [account] to [source], or else what it is.
String _lineOf(Account account, SourceAccount source) {
  final digits = account.lastDigits;
  final match = matchOf(account, source);
  if (match == null) {
    return accountLine(
      currency: account.openingBalance.currency.code,
      type: account.type.name,
      lastDigits: digits,
    );
  }
  return [if (digits != null) '••$digits', matchLabel(match)].join(' · ');
}

/// A line of the summary: what it counts, and how much, with a check when
/// it agrees with the bank and a mark of attention when it does not.
class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.matches});

  final String label;
  final Widget value;
  final bool? matches;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BirkaTokens.spaceXxs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: styles.body.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: BirkaTokens.spaceSm),
          DefaultTextStyle.merge(
            style: styles.bodyStrong.copyWith(color: colors.text),
            child: value,
          ),
          if (matches case final matches?) ...[
            const SizedBox(width: BirkaTokens.spaceXs),
            Semantics(
              label: matches
                  ? t.imports.balanceMatches
                  : t.imports.balanceDiffers,
              child: BirkaIcon(
                matches ? BirkaGlyph.check : BirkaGlyph.alert,
                size: 16,
                color: matches
                    ? colors.positive
                    : const Color(BirkaTokens.colorPaletteAmber),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The round check of an import that came in.
class _DoneMark extends StatelessWidget {
  const _DoneMark();

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
        child: BirkaIcon(BirkaGlyph.check, size: 24, color: colors.onAccent),
      ),
    );
  }
}
