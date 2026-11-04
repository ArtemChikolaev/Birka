import 'package:ledger/src/civil_date.dart';
import 'package:meta/meta.dart';

/// A statement that came into the ledger at once, as the list of past
/// imports shows it (ADR 0021).
@immutable
final class LedgerImport {
  /// Creates an import.
  const LedgerImport({
    required this.id,
    required this.fileName,
    required this.firstDay,
    required this.lastDay,
    required this.importedAt,
    required this.transactions,
    required this.accountIds,
    this.format,
  });

  /// The id.
  final String id;

  /// The name of the file, as the person chose it.
  final String fileName;

  /// The day of its first operation.
  final CivilDate firstDay;

  /// The day of its last operation.
  final CivilDate lastDay;

  /// When it came in.
  final DateTime importedAt;

  /// How many of its transactions the ledger still holds.
  final int transactions;

  /// The accounts that its transactions move money on.
  final Set<String> accountIds;

  /// The id of its known format, such as `tbank`, or `null` for columns that
  /// a person named.
  final String? format;
}
