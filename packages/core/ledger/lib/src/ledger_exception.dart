/// Thrown when a write would break the ledger: it refers to a row that does
/// not exist, or does not fit the account or the category.
final class LedgerException implements Exception {
  /// Creates an exception that says what is wrong.
  const LedgerException(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'LedgerException: $message';
}
