import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:transactions_common/transactions_common.dart';

/// The picture of an operation: its category, two arrows for a transfer, or a
/// check mark for a correction.
class OperationBadge extends StatelessComponent {
  /// Creates a badge of [operation].
  const OperationBadge(this.operation, {this.size = 40, super.key});

  /// The operation.
  final Operation operation;

  /// The width and the height in pixels.
  final int size;

  @override
  Component build(BuildContext context) {
    return GlyphBadge(
      size: size,
      glyph: switch (operation.kind) {
        TransactionKind.transfer => BirkaGlyph.transfer,
        TransactionKind.adjustment => BirkaGlyph.check,
        _ => BirkaGlyph.named(operation.category?.icon),
      },
      color: operation.category?.color ?? 'var(--color-text-muted)',
    );
  }
}
