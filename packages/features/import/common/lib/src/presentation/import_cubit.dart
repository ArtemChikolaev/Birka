import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:import_common/src/domain/import_defaults.dart';
import 'package:import_common/src/domain/import_memory.dart';
import 'package:import_common/src/domain/import_plan.dart';
import 'package:import_common/src/domain/import_repository.dart';
import 'package:import_common/src/domain/statement.dart';
import 'package:import_common/src/domain/statement_files.dart';
import 'package:import_common/src/domain/statement_format.dart';
import 'package:import_common/src/domain/statement_formats.dart';
import 'package:import_common/src/domain/statement_layout.dart';
import 'package:import_common/src/domain/statement_reader.dart';
import 'package:import_common/src/domain/statement_table.dart';
import 'package:import_common/src/presentation/import_labels.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:money/money.dart';

/// The steps of the import, as the boards draw them.
enum ImportStep {
  /// The file, and the past imports.
  file,

  /// The bank or the app the file comes from.
  format,

  /// What each column holds, and the categories of the bank.
  columns,

  /// Where each account of the file goes.
  account,

  /// What the ledger already has.
  copies,

  /// What came in, and its undo.
  done,
}

/// Where the import of a statement stands.
@immutable
final class ImportState {
  /// Creates a state.
  const ImportState({
    this.step = ImportStep.file,
    this.reading = false,
    this.unreadable,
    this.table,
    this.layout,
    this.statement,
    this.choices,
    this.plan,
    this.accounts = const [],
    this.categories = const [],
    this.progress,
    this.importId,
    this.undone = false,
    this.failed = false,
    this.history = const [],
    this.seen = ImportStep.file,
    this.balances = const {},
    this.currency = Currency.rub,
  });

  /// The step on screen.
  final ImportStep step;

  /// Whether a file is being read.
  final bool reading;

  /// Why the last file did not read.
  final UnreadableReason? unreadable;

  /// The table of the file.
  final StatementTable? table;

  /// How the table reads.
  final StatementLayout? layout;

  /// What the table holds, read by [layout].
  final Statement? statement;

  /// What the person chose, and what Birka chose until they do.
  final ImportChoices? choices;

  /// What the import will do, once the choices let it be planned.
  final ImportPlan? plan;

  /// The accounts of the ledger, to choose from.
  final List<Account> accounts;

  /// The categories of the ledger of both kinds, to choose from.
  final List<Category> categories;

  /// How far the writing has come, while it goes on.
  final ({int done, int total})? progress;

  /// The import once it is in the ledger.
  final String? importId;

  /// Whether the person took the import back out.
  final bool undone;

  /// Whether the writing failed, which leaves the ledger as it was.
  final bool failed;

  /// The past imports, the latest first.
  final List<LedgerImport> history;

  /// The furthest step that the person opened since the file came.
  final ImportStep seen;

  /// What each account of the ledger holds today, by its id.
  final Map<String, Money> balances;

  /// The currency of a file that names none: the base currency of the device.
  final Currency currency;

  /// The name of the file.
  String? get fileName => table?.fileName;

  /// Whether the columns let rows become operations.
  bool get readable =>
      layout != null &&
      layout!.missing.isEmpty &&
      (statement?.rows.isNotEmpty ?? false);

  /// Whether the import is being written.
  bool get writing => progress != null && importId == null;

  /// Whether [plan] follows the latest [choices], so that it can be written.
  bool get planned => plan != null && identical(plan!.choices, choices);

  /// Whether the choices can change: before the writing starts.
  bool get open => !writing && importId == null;

  /// The furthest step that the person can open now.
  ImportStep get furthest {
    if (importId != null) return ImportStep.done;
    if (table == null) return ImportStep.file;
    if (!readable) return ImportStep.columns;
    if (plan == null) return ImportStep.account;
    return ImportStep.copies;
  }

  /// The furthest step that the person opened and can open again now.
  ImportStep get reachable => seen.index < furthest.index ? seen : furthest;

  ImportState _with({
    ImportStep? step,
    bool? reading,
    Object? unreadable = _same,
    Object? table = _same,
    Object? layout = _same,
    Object? statement = _same,
    Object? choices = _same,
    Object? plan = _same,
    List<Account>? accounts,
    List<Category>? categories,
    Object? progress = _same,
    Object? importId = _same,
    bool? undone,
    bool? failed,
    List<LedgerImport>? history,
    ImportStep? seen,
    Map<String, Money>? balances,
  }) => ImportState(
    step: step ?? this.step,
    reading: reading ?? this.reading,
    unreadable: identical(unreadable, _same)
        ? this.unreadable
        : unreadable as UnreadableReason?,
    table: identical(table, _same) ? this.table : table as StatementTable?,
    layout: identical(layout, _same) ? this.layout : layout as StatementLayout?,
    statement: identical(statement, _same)
        ? this.statement
        : statement as Statement?,
    choices: identical(choices, _same)
        ? this.choices
        : choices as ImportChoices?,
    plan: identical(plan, _same) ? this.plan : plan as ImportPlan?,
    accounts: accounts ?? this.accounts,
    categories: categories ?? this.categories,
    progress: identical(progress, _same)
        ? this.progress
        : progress as ({int done, int total})?,
    importId: identical(importId, _same) ? this.importId : importId as String?,
    undone: undone ?? this.undone,
    failed: failed ?? this.failed,
    history: history ?? this.history,
    seen: seen ?? this.seen,
    balances: balances ?? this.balances,
    currency: currency,
  );

  static const _same = Object();
}

/// The import of a statement, step by step (ADR 0021): the file, how it
/// reads, where its accounts and categories go, what the ledger already
/// has, and the writing with its undo.
///
/// Birka chooses what it can on its own: what the person chose for the last
/// file of the format, an account of the same card or name, a category of
/// the same name. The plan follows every choice.
final class ImportCubit extends Cubit<ImportState> {
  /// Creates the import on [_repository], reading files with [_reader] and
  /// letting the person choose them through [_files]. A file that names no
  /// currency is in [currency], the base currency of the device. [remembered]
  /// keeps the formats of one's own and the choices of each format for the
  /// next file. [today] says what day it is, which tests can fix.
  ImportCubit(
    this._repository,
    this._reader,
    this._files, {
    Currency currency = Currency.rub,
    ImportMemory? remembered,
    CivilDate Function()? today,
  }) : _remembered = remembered,
       _today = today ?? _now,
       super(ImportState(currency: currency));

  final ImportRepository _repository;
  final StatementReader _reader;
  final StatementFiles _files;
  final ImportMemory? _remembered;
  final CivilDate Function() _today;

  static CivilDate _now() => CivilDate.of(DateTime.now());
  StreamSubscription<List<LedgerImport>>? _history;

  /// The number of the latest plan, so that an older one that comes late is
  /// dropped.
  var _planned = 0;

  /// What the past choices of the person teach the plan, read with the
  /// ledger.
  CategoryMemory? _memory;

  /// Follows the past imports and reads what there is to choose from.
  Future<void> start() async {
    _history ??= _repository.watchImports().listen(
      (history) {
        if (!isClosed) emit(state._with(history: history));
      },
      onError: (Object _) {
        if (!isClosed) emit(state._with(failed: true));
      },
    );
    await _readLedger();
  }

  Future<void> _readLedger() async {
    try {
      final accounts = await _repository.accounts();
      final categories = [
        ...await _repository.categories(CategoryKind.expense),
        ...await _repository.categories(CategoryKind.income),
      ];
      _memory = await learnFrom(_repository);
      final today = _today();
      final balances = {
        for (final account in accounts)
          if (!account.archived)
            account.id: await _repository.balanceOn(account.id, today),
      };
      if (isClosed) return;
      emit(
        state._with(
          accounts: accounts,
          categories: categories,
          balances: balances,
        ),
      );
    } on Object {
      if (!isClosed) emit(state._with(failed: true));
    }
  }

  /// Lets the person choose a file, and reads it.
  Future<void> choose() async {
    final file = await _files.choose();
    if (file != null) await read(file.name, file.bytes);
  }

  /// Reads the file [name] of [bytes], which a person chose or dropped, and
  /// goes on to its format.
  Future<void> read(String name, Uint8List bytes) async {
    if (state.reading || state.writing) return;
    emit(state._with(reading: true, unreadable: null));
    try {
      final table = await _reader.read(name, bytes);
      if (isClosed) return;
      final layout = detectLayout(
        table,
        formats: [...statementFormats, ...?_remembered?.formats],
      );
      _show(table, asOwnFormat(layout), step: ImportStep.format, fresh: true);
    } on UnreadableFile catch (error) {
      if (isClosed) return;
      emit(_fresh()._with(unreadable: error.reason));
    }
  }

  /// Reads the file as [format], or as columns of its own when it is `null`.
  void useFormat(StatementFormat? format) {
    final table = state.table;
    if (table == null || !state.open) return;
    _show(
      table,
      format == null
          ? guessLayout(table)
          : asOwnFormat(layoutAs(table, format)),
    );
  }

  /// Gives [column] the role [role].
  void setRole(int column, ColumnRole role) {
    final layout = state.layout;
    if (layout == null || !state.open) return;
    _show(state.table!, layout.withRole(column, role));
  }

  /// Reads the values as [options] say.
  void setOptions(ReadingOptions options) {
    final layout = state.layout;
    if (layout == null || !state.open) return;
    _show(state.table!, layout.withOptions(options));
  }

  /// Sends the operations of the account [key] of the file to [choice].
  void chooseAccount(String key, AccountChoice choice) {
    final choices = state.choices;
    if (choices == null) return;
    _choose(
      ImportChoices(
        accounts: {...choices.accounts, key: choice},
        categories: choices.categories,
        fees: choices.fees,
        keep: choices.keep,
      ),
    );
  }

  /// Sends the operations of the category [category] of the bank to
  /// [choice].
  void chooseCategory(BankCategory category, CategoryChoice choice) {
    final choices = state.choices;
    if (choices == null) return;
    _choose(
      ImportChoices(
        accounts: choices.accounts,
        categories: {...choices.categories, category: choice},
        fees: choices.fees,
        keep: choices.keep,
      ),
    );
  }

  /// Sends fees to [choice].
  void chooseFees(CategoryChoice choice) {
    final choices = state.choices;
    if (choices == null) return;
    _choose(
      ImportChoices(
        accounts: choices.accounts,
        categories: choices.categories,
        fees: choice,
        keep: choices.keep,
      ),
    );
  }

  /// Lets the operation of the row [line] go in although it looks like a
  /// transaction of the ledger, or keeps it out again.
  void keep(int line, {required bool keep}) {
    final choices = state.choices;
    if (choices == null) return;
    _choose(
      choices.keeping({
        ...choices.keep.where((it) => it != line),
        if (keep) line,
      }),
    );
  }

  /// Opens [step], when it is not past [ImportState.furthest].
  void goTo(ImportStep step) {
    if (state.writing || step.index > state.furthest.index) return;
    if (state.importId != null && step != ImportStep.done) return;
    final seen = step.index > state.seen.index ? step : state.seen;
    emit(state._with(step: step, seen: seen));
  }

  /// Opens the step after the one on screen.
  void next() {
    final index = state.step.index + 1;
    if (index < ImportStep.done.index) goTo(ImportStep.values[index]);
  }

  /// Opens the step before the one on screen.
  void back() {
    final index = state.step.index - 1;
    if (index >= 0) goTo(ImportStep.values[index]);
  }

  /// Puts the plan into the ledger at once and goes on to its result.
  Future<void> write() async {
    final plan = state.plan;
    final fileName = state.fileName;
    if (!state.planned || !state.open || fileName == null) return;
    final total = plan!.added.length;
    if (total == 0) return;
    final accounts = {for (final account in state.accounts) account.id};
    final categories = {for (final category in state.categories) category.id};
    emit(state._with(progress: (done: 0, total: total), failed: false));
    try {
      final id = await _repository.write(
        plan,
        fileName: fileName,
        format: state.layout?.format?.id,
        progress: (done, total) {
          if (!isClosed) {
            emit(state._with(progress: (done: done, total: total)));
          }
        },
      );
      if (isClosed) return;
      emit(
        state._with(step: ImportStep.done, seen: ImportStep.done, importId: id),
      );
      await _readLedger();
      await _keep(plan, accounts: accounts, categories: categories);
    } on Object {
      if (isClosed) return;
      emit(state._with(progress: null, failed: true));
    }
  }

  /// Takes the import that just went in back out.
  Future<void> undo() async {
    final id = state.importId;
    if (id == null || state.undone) return;
    try {
      await _repository.undo(id);
    } on Object {
      if (!isClosed) emit(state._with(failed: true));
      return;
    }
    if (isClosed) return;
    emit(state._with(undone: true, failed: false));
    await _readLedger();
  }

  /// Takes the past import [id] back out, and plans the file on screen again
  /// on what stays.
  Future<void> undoPast(String id) async {
    if (id == state.importId) return undo();
    if (state.writing) return;
    try {
      await _repository.undo(id);
    } on Object {
      if (!isClosed) emit(state._with(failed: true));
      return;
    }
    await _readLedger();
    final choices = state.choices;
    if (isClosed || choices == null || state.importId != null) return;
    _choose(choices);
  }

  /// Starts again with another file.
  void restart() => emit(_fresh());

  ImportState _fresh() => ImportState(
    history: state.history,
    accounts: state.accounts,
    categories: state.categories,
    balances: state.balances,
    currency: state.currency,
  );

  void _show(
    StatementTable table,
    StatementLayout layout, {
    ImportStep? step,
    bool fresh = false,
  }) {
    final base = fresh ? _fresh() : state;
    final statement = readStatement(table, layout);
    emit(
      base._with(
        step: step,
        seen: step != null && step.index > base.seen.index ? step : null,
        reading: false,
        table: table,
        layout: layout,
        statement: statement,
        choices: _defaults(
          statement,
          layout.format,
          before: base.choices ?? _keptFor(statement, layout.format),
        ),
        plan: null,
      ),
    );
    unawaited(_plan());
  }

  /// Takes [choices], with Birka's own for what they leave open, and plans
  /// the import by them.
  void _choose(ImportChoices choices) {
    final statement = state.statement;
    if (statement == null || !state.open) return;
    emit(
      state._with(
        choices: _defaults(statement, state.layout?.format, before: choices),
      ),
    );
    unawaited(_plan());
  }

  /// The choices for [statement]: those of [before] that still fit the
  /// ledger, and Birka's own for the rest.
  ImportChoices _defaults(
    Statement statement,
    StatementFormat? format, {
    required ImportChoices? before,
  }) {
    final names = newAccountNames(statement.accounts, format);
    final create = _ownCategories.contains(format?.id);
    final presets = presetCategories(state.categories);
    final accounts = {
      for (final source in statement.accounts)
        source.key: switch (before?.accounts[source.key]) {
          final choice? when _fits(choice) => choice,
          _ => defaultAccount(
            source,
            state.accounts,
            newName: names[source.key]!,
            fallback: state.currency,
          ),
        },
    };
    final leftOut = {
      for (final MapEntry(:key, :value) in accounts.entries)
        if (value is LeaveOut) key,
    };
    return ImportChoices(
      accounts: accounts,
      categories: {
        for (final category in bankCategoriesOf(statement, leftOut: leftOut))
          category: switch (before?.categories[category]) {
            final choice? when _fitsCategory(choice) => choice,
            _ => defaultCategory(
              category,
              state.categories,
              create: create,
              presets: presets,
            ),
          },
      },
      fees: switch (before?.fees) {
        final fees? when _fitsCategory(fees) => fees,
        _ => const Unsorted(),
      },
      keep: before?.keep ?? const {},
    );
  }

  /// What the person chose for the last file of [format], as choices for the
  /// accounts of [statement] and the categories that are still there.
  ImportChoices? _keptFor(Statement statement, StatementFormat? format) {
    final kept = format == null ? null : _remembered?.choicesOf(format.id);
    if (kept == null) return null;
    final ledger = {
      for (final account in state.accounts) account.id: account,
    };
    final accounts = <String, AccountChoice>{};
    for (final source in statement.accounts) {
      final key = sourceKeyOf(source);
      if (!kept.accounts.containsKey(key)) continue;
      final id = kept.accounts[key];
      if (id == null) {
        accounts[source.key] = const LeaveOut();
      } else if (ledger[id] case final account?) {
        accounts[source.key] = IntoAccount(account);
      }
    }
    final fees = kept.fees;
    return ImportChoices(
      accounts: accounts,
      categories: {
        for (final MapEntry(:key, :value) in kept.categories.entries)
          key: IntoCategory(value),
      },
      fees: fees == null ? const Unsorted() : IntoCategory(fees),
    );
  }

  /// Keeps the format of the import that went in, when it is the person's
  /// own, and what the person chose for it, for its next file. An account or
  /// a category that the import made counts by its name among those that
  /// were not there before, of [accounts] and [categories].
  Future<void> _keep(
    ImportPlan plan, {
    required Set<String> accounts,
    required Set<String> categories,
  }) async {
    final remembered = _remembered;
    final table = state.table;
    final layout = state.layout;
    if (remembered == null || table == null || layout == null) return;
    final format = layout.format == null || isOwnFormat(layout.format)
        ? ownFormatOf(table, layout)
        : layout.format;
    if (format == null) return;
    String? made(String name) => state.accounts
        .where((it) => !accounts.contains(it.id) && it.name == name)
        .firstOrNull
        ?.id;
    String? categoryOf(CategoryChoice choice) => switch (choice) {
      IntoCategory(:final categoryId) => categoryId,
      NewCategory(:final name) =>
        state.categories
            .where((it) => !categories.contains(it.id) && it.name == name)
            .firstOrNull
            ?.id,
      Unsorted() => null,
    };
    try {
      await remembered.remember(
        format,
        RememberedChoices(
          accounts: {
            for (final source in state.statement?.accounts ?? <SourceAccount>[])
              if (plan.choices.accounts[source.key] case final choice?)
                ...switch (choice) {
                  IntoAccount(:final account) => {
                    sourceKeyOf(source): account.id,
                  },
                  NewAccount(:final name) => {sourceKeyOf(source): ?made(name)},
                  LeaveOut() => {sourceKeyOf(source): null},
                },
          },
          categories: {
            for (final MapEntry(:key, :value)
                in plan.choices.categories.entries)
              key: ?categoryOf(value),
          },
          fees: categoryOf(plan.choices.fees),
        ),
      );
    } on Object {
      // The import went in; only the next file asks again.
    }
  }

  bool _fits(AccountChoice choice) => switch (choice) {
    IntoAccount(:final account) => state.accounts.any(
      (it) => it.id == account.id && !it.archived,
    ),
    _ => true,
  };

  bool _fitsCategory(CategoryChoice choice) => switch (choice) {
    IntoCategory(:final categoryId) => state.categories.any(
      (it) => it.id == categoryId && !it.archived,
    ),
    NewCategory(:final parentId?) => state.categories.any(
      (it) => it.id == parentId && !it.archived,
    ),
    _ => true,
  };

  Future<void> _plan() async {
    final number = ++_planned;
    final statement = state.statement;
    final choices = state.choices;
    if (statement == null || choices == null || !state.readable) return;
    try {
      final plan = await prepareImport(
        _repository,
        statement,
        choices,
        memory: _memory,
      );
      if (isClosed || number != _planned) return;
      emit(state._with(plan: plan, failed: false));
    } on Object {
      if (isClosed || number != _planned) return;
      emit(state._with(failed: true));
    }
  }

  /// The formats whose categories are a person's own, which come in as new
  /// categories rather than into the inbox.
  static const _ownCategories = {'zenmoney'};

  @override
  Future<void> close() async {
    await _history?.cancel();
    return super.close();
  }
}
