import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The icons of the design system. Each one is an SVG file in `icons/`.
enum BirkaGlyph {
  /// A house.
  home,

  /// A list with bullets.
  list,

  /// A pie chart.
  reports,

  /// Four squares.
  more,

  /// A plus sign.
  plus,

  /// A cross.
  close,

  /// An arrow to the previous screen.
  back,

  /// An arrow to the next screen.
  chevron,

  /// A check mark.
  check,

  /// A shopping cart.
  cart,

  /// A cup.
  cup,

  /// A bus.
  bus,

  /// A heart.
  heart,

  /// A strip of film.
  ticket,

  /// Two arrows in a circle.
  repeat,

  /// A shirt.
  shirt,

  /// A paper plane.
  plane,

  /// A book.
  book,

  /// A gift box.
  gift,

  /// A briefcase.
  briefcase,

  /// A wallet.
  wallet,

  /// A percent sign.
  percent,
}

/// An icon in the color of [color] or of the surrounding [IconTheme].
class BirkaIcon extends StatelessWidget {
  /// Creates an icon of [glyph].
  const BirkaIcon(this.glyph, {this.size = 22, this.color, super.key});

  /// What the icon shows.
  final BirkaGlyph glyph;

  /// The width and the height.
  final double size;

  /// The color of the strokes.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'icons/${glyph.name}.svg',
      package: 'design_flutter',
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color ?? IconTheme.of(context).color!),
    );
  }
}
