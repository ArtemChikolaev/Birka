import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:flutter/widgets.dart';

/// The dot of the color of a category, given as `#RRGGBB`, or a quiet one
/// when the category has none: the mark of a category among choices.
class CategoryDot extends StatelessWidget {
  /// Creates the dot of [color].
  const CategoryDot(this.color, {super.key});

  /// The color of the category, or `null` when it has none.
  final String? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color == null
            ? BirkaColors.of(context).textSubtle
            : BirkaColors.fromHex(color),
        shape: BoxShape.circle,
      ),
    );
  }
}
