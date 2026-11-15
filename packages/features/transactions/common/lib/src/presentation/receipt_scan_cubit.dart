import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:transactions_common/src/domain/operation.dart';
import 'package:transactions_common/src/domain/receipt_qr.dart';
import 'package:transactions_common/src/domain/transactions_repository.dart';

/// Where the scanner of receipts stands (ADR 0032).
enum ReceiptScanStatus {
  /// It looks for a code.
  looking,

  /// The last code it saw is not the code of a receipt; it keeps looking.
  notReceipt,

  /// It read a receipt that the ledger does not have yet.
  read,

  /// It read a receipt that the ledger already has.
  twice,
}

/// What the scanner of receipts saw.
@immutable
final class ReceiptScanState {
  /// Creates a state.
  const ReceiptScanState({
    this.status = ReceiptScanStatus.looking,
    this.read,
    this.recorded,
  });

  /// Where the scanner stands.
  final ReceiptScanStatus status;

  /// The receipt it read.
  final ReceiptQr? read;

  /// The operation that the ledger already made from the receipt.
  final Operation? recorded;
}

/// Reads the codes that the camera sees until one is a receipt, and tells a
/// receipt that the ledger already has from a new one, so that a receipt goes
/// into the ledger once (ADR 0032).
class ReceiptScanCubit extends Cubit<ReceiptScanState> {
  /// Creates the scanner, looking.
  ReceiptScanCubit(this._repository) : super(const ReceiptScanState());

  final TransactionsRepository _repository;

  /// The text of the last code, which the camera sees many times a second.
  String? _last;

  /// Whether the ledger is being asked about a receipt.
  bool _checking = false;

  /// Takes the text of a code that the camera saw. Once a receipt is read
  /// the scanner stops taking codes.
  Future<void> codeSeen(String text) async {
    final status = state.status;
    if (_checking ||
        status == ReceiptScanStatus.read ||
        status == ReceiptScanStatus.twice ||
        text == _last) {
      return;
    }
    _last = text;
    final read = ReceiptQr.parse(text);
    if (read == null) {
      emit(const ReceiptScanState(status: ReceiptScanStatus.notReceipt));
      return;
    }
    _checking = true;
    Operation? recorded;
    try {
      recorded = await _repository.operationOfReceipt(read.receipt);
    } on Exception {
      // A ledger that cannot answer lets the receipt through: quick add
      // still shows it before anything is saved.
      recorded = null;
    } finally {
      _checking = false;
    }
    if (isClosed) return;
    emit(
      recorded == null
          ? ReceiptScanState(status: ReceiptScanStatus.read, read: read)
          : ReceiptScanState(
              status: ReceiptScanStatus.twice,
              read: read,
              recorded: recorded,
            ),
    );
  }

  /// Looks for another code after a receipt that the ledger already had.
  void lookAgain() {
    _last = null;
    emit(const ReceiptScanState());
  }
}
