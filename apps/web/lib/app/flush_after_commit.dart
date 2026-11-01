import 'package:drift/drift.dart';

/// Holds a commit back until the data is safe. Drift waits for the storage
/// after a lone statement but not after a transaction, and a page can leave
/// the moment a form closes (ADR 0009).
final class FlushAfterCommit extends QueryInterceptor {
  /// Creates the interceptor. [_flush] finishes when all writes so far are
  /// stored.
  FlushAfterCommit(this._flush);

  final Future<void> Function() _flush;

  @override
  Future<void> commitTransaction(TransactionExecutor inner) async {
    await inner.send();
    await _flush();
  }
}
