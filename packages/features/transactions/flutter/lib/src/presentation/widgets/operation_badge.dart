import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:transactions_common/transactions_common.dart';

/// The picture of an operation: its category, or two arrows for a transfer.
class OperationBadge extends StatelessWidget {
  /// Creates a badge of [operation].
  const OperationBadge(this.operation, {this.size = 40, super.key});

  /// The operation.
  final Operation operation;

  /// The width and the height.
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = operation.category?.color;
    return GlyphBadge(
      size: size,
      glyph: operation.kind == TransactionKind.transfer
          ? BirkaGlyph.transfer
          : BirkaGlyph.named(operation.category?.icon),
      color: color == null
          ? BirkaColors.of(context).textMuted
          : BirkaColors.fromHex(color),
    );
  }
}
