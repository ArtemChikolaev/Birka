import 'dart:async';
import 'dart:convert';

import 'package:backup_common/src/domain/backup_files.dart';
import 'package:backup_common/src/domain/backup_repository.dart';
import 'package:backup_common/src/domain/file_names.dart';
import 'package:backup_common/src/domain/operations_csv.dart';
import 'package:backup_common/src/presentation/backup_labels.dart';
import 'package:bloc/bloc.dart';
import 'package:device_settings/device_settings.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';

/// What the data screen is busy with. Its buttons wait until it is done.
enum BackupTask {
  /// Making a copy and saving it.
  saving,

  /// Reading a chosen file.
  opening,

  /// Putting a copy in place of the ledger.
  restoring,

  /// Making a table of the operations and saving it.
  exporting,

  /// Removing everything.
  wiping,
}

/// A copy read from a file, which waits for a yes before it replaces the
/// ledger.
@immutable
final class CopyOffer {
  /// Creates an offer of [copy] from the file [fileName].
  const CopyOffer({required this.fileName, required this.copy});

  /// The name of the file.
  final String fileName;

  /// What the file holds.
  final LedgerCopy copy;
}

/// What came of the last action, for a short message on the screen.
@immutable
sealed class BackupNotice {
  const BackupNotice();

  /// Whether it says that something went wrong.
  bool get isTrouble => false;
}

/// A copy was saved as [fileName].
final class CopySaved extends BackupNotice {
  /// Creates the notice.
  const CopySaved(this.fileName);

  /// The name of the file.
  final String fileName;
}

/// The ledger became the copy made at [madeAt].
final class CopyRestored extends BackupNotice {
  /// Creates the notice.
  const CopyRestored(this.madeAt);

  /// When the copy was made.
  final DateTime madeAt;
}

/// The operations were saved as [fileName].
final class OperationsExported extends BackupNotice {
  /// Creates the notice.
  const OperationsExported(this.fileName);

  /// The name of the file.
  final String fileName;
}

/// The ledger is empty now.
final class LedgerWiped extends BackupNotice {
  /// Creates the notice.
  const LedgerWiped();
}

/// A chosen file cannot become the ledger, because of [problem].
final class CopyRefused extends BackupNotice {
  /// Creates the notice.
  const CopyRefused(this.problem);

  /// What is wrong with the file.
  final LedgerCopyProblem problem;

  @override
  bool get isTrouble => true;
}

/// Something failed, and nothing changed.
final class BackupFailed extends BackupNotice {
  /// Creates the notice.
  const BackupFailed();

  @override
  bool get isTrouble => true;
}

/// What the data screen shows.
@immutable
final class BackupState {
  /// Creates the state.
  const BackupState({
    this.counts,
    this.lastCopyAt,
    this.task,
    this.offer,
    this.notice,
  });

  /// How much the ledger holds, or `null` until it is read.
  final LedgerCounts? counts;

  /// When this device last saved a copy.
  final DateTime? lastCopyAt;

  /// What is going on, or `null` when nothing is.
  final BackupTask? task;

  /// A copy that waits for a yes.
  final CopyOffer? offer;

  /// What came of the last action. A new action clears it first, so the same
  /// notice twice in a row still comes as news.
  final BackupNotice? notice;

  /// A copy with the given fields changed. [task], [offer] and [notice] are in
  /// records, because `null` is a value for them.
  BackupState copyWith({
    LedgerCounts? counts,
    DateTime? lastCopyAt,
    (BackupTask?,)? task,
    (CopyOffer?,)? offer,
    (BackupNotice?,)? notice,
  }) {
    return BackupState(
      counts: counts ?? this.counts,
      lastCopyAt: lastCopyAt ?? this.lastCopyAt,
      task: task == null ? this.task : task.$1,
      offer: offer == null ? this.offer : offer.$1,
      notice: notice == null ? this.notice : notice.$1,
    );
  }
}

/// Saves the ledger to a file and brings it back, saves its operations as a
/// table, and removes it all (ADR 0016).
class BackupCubit extends Cubit<BackupState> {
  /// Creates the cubit on [_repository], which it starts to follow, and on
  /// the [_files] and the [_store] of the host. Tests can fix [now].
  BackupCubit(
    this._repository,
    this._files,
    this._store, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(BackupState(lastCopyAt: _lastCopyIn(_store))) {
    _counts = _repository.watchCounts().listen(
      (counts) => emit(state.copyWith(counts: counts)),
      // The numbers stay away, and the buttons work without them.
      onError: (Object _) {},
    );
  }

  /// Where the store keeps the moment of the last copy.
  static const lastCopyKey = 'last-copy-at';

  final BackupRepository _repository;
  final BackupFiles _files;
  final SettingsStore _store;
  final DateTime Function() _now;
  late final StreamSubscription<LedgerCounts> _counts;

  static DateTime? _lastCopyIn(SettingsStore store) =>
      DateTime.tryParse(store.read(lastCopyKey) ?? '')?.toUtc();

  /// Makes a copy and lets the person save it.
  Future<void> save() => _run(BackupTask.saving, () async {
    final copy = await _repository.copy();
    final name = copyFileName(copy.madeAt);
    final saved = await _files.save(
      name: name,
      type: copyFileType,
      bytes: utf8.encode(copy.encode()),
    );
    if (!saved) return state;
    await _store.write(lastCopyKey, copy.madeAt.toIso8601String());
    return state.copyWith(
      lastCopyAt: copy.madeAt,
      notice: (CopySaved(name),),
    );
  });

  /// Lets the person choose a copy and reads it. A copy that can become the
  /// ledger waits in [BackupState.offer] for [restore] or [dismiss].
  Future<void> open() => _run(BackupTask.opening, () async {
    final file = await _files.open();
    if (file == null) return state;
    const tooLarge = LedgerCopyException(
      LedgerCopyProblem.notACopy,
      'Too large for a copy',
    );
    if ((await file.length() ?? 0) > largestCopy) throw tooLarge;
    final bytes = await file.read();
    if (bytes.length > largestCopy) throw tooLarge;
    final copy = LedgerCopy.parse(utf8.decode(bytes));
    return state.copyWith(
      offer: (CopyOffer(fileName: file.name, copy: copy),),
    );
  });

  /// Puts the copy on offer in place of the ledger.
  Future<void> restore() async {
    final offer = state.offer;
    if (offer == null || state.task != null) return;
    emit(state.copyWith(offer: (null,)));
    await _run(BackupTask.restoring, () async {
      await _repository.restore(offer.copy);
      return state.copyWith(notice: (CopyRestored(offer.copy.madeAt),));
    });
  }

  /// Lets the copy on offer go.
  void dismiss() => emit(state.copyWith(offer: (null,)));

  /// Makes a table of the operations and lets the person save it.
  Future<void> export() => _run(BackupTask.exporting, () async {
    final operations = await _repository.operations();
    final name = operationsFileName(_now());
    final saved = await _files.save(
      name: name,
      type: operationsFileType,
      bytes: utf8.encode(operationsCsv(operations, csvLanguage())),
    );
    return saved ? state.copyWith(notice: (OperationsExported(name),)) : state;
  });

  /// Removes everything the ledger holds.
  Future<void> wipe() => _run(BackupTask.wiping, () async {
    await _repository.wipe();
    return state.copyWith(notice: (const LedgerWiped(),));
  });

  /// Runs [work] as [task], unless another task runs, and shows the state
  /// that it comes to. A failure leaves everything as it was and says so.
  Future<void> _run(
    BackupTask task,
    Future<BackupState> Function() work,
  ) async {
    if (state.task != null) return;
    emit(state.copyWith(task: (task,), notice: (null,)));
    BackupState next;
    try {
      next = await work();
    } on LedgerCopyException catch (error) {
      next = state.copyWith(notice: (CopyRefused(error.problem),));
    } on FormatException {
      // Bytes that are not UTF-8.
      next = state.copyWith(
        notice: (const CopyRefused(LedgerCopyProblem.notACopy),),
      );
    } on Exception {
      next = state.copyWith(notice: (const BackupFailed(),));
    }
    if (!isClosed) emit(next.copyWith(task: (null,)));
  }

  @override
  Future<void> close() async {
    await _counts.cancel();
    return super.close();
  }
}
