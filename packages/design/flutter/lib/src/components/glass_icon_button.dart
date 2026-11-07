import 'dart:async';

import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/components/glass_surface.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A round button of glass with an icon, such as the way back from a screen.
class GlassIconButton extends StatelessWidget {
  /// Creates a button with [glyph]. Screen readers read [label].
  const GlassIconButton({
    required this.glyph,
    required this.label,
    required this.onPressed,
    this.glass = true,
    this.badge,
    super.key,
  });

  /// What the button shows.
  final BirkaGlyph glyph;

  /// What the button does, for screen readers.
  final String label;

  /// Called on a tap.
  final VoidCallback onPressed;

  /// Whether the icon sits on a round of glass. The cross that closes a form
  /// goes without it.
  final bool glass;

  /// How many new things wait behind the button, such as the new notices
  /// behind the bell, on its corner: the count jumps once when it grows, and
  /// shrinks away at nought. A button that never counts leaves it `null`.
  /// [label] says the count itself.
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final icon = SizedBox.square(
      dimension: BirkaTokens.sizeTouchTarget,
      child: Center(child: BirkaIcon(glyph)),
    );
    final button = glass
        ? GlassSurface(
            borderRadius: const BorderRadius.all(
              Radius.circular(BirkaTokens.radiusPill),
            ),
            padding: EdgeInsets.zero,
            child: icon,
          )
        : icon;
    final badge = this.badge;
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: badge == null
            ? button
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  button,
                  Positioned(
                    top: -BirkaTokens.spaceXxs,
                    right: -BirkaTokens.spaceXxs,
                    child: _Count(badge),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The count on the corner of a [GlassIconButton].
class _Count extends StatefulWidget {
  const _Count(this.count);

  final int count;

  @override
  State<_Count> createState() => _CountState();
}

class _CountState extends State<_Count> {
  // The figure stays while the count shrinks away at nought.
  late int _shown = widget.count;
  bool _jumping = false;
  Timer? _settle;

  @override
  void didUpdateWidget(_Count old) {
    super.didUpdateWidget(old);
    if (widget.count > 0) _shown = widget.count;
    // A count that grows jumps up for a moment and settles with a bounce.
    if (old.count > 0 && widget.count > old.count && !_reduced) {
      _jumping = true;
      _settle?.cancel();
      _settle = Timer(BirkaMotion.fast, () {
        if (mounted) setState(() => _jumping = false);
      });
    }
  }

  bool get _reduced => BirkaMotion.reduced(context);

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final reduced = _reduced;
    final on = widget.count > 0;
    final scale = reduced
        ? 1.0
        : !on
        ? 0.4
        : _jumping
        ? 1.3
        : 1.0;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: on ? 1 : 0,
        duration: BirkaMotion.base,
        curve: BirkaMotion.fadeCurve,
        child: AnimatedScale(
          scale: scale,
          duration: _jumping ? BirkaMotion.fast : BirkaMotion.slow,
          curve: _jumping ? BirkaMotion.standardCurve : BirkaMotion.springCurve,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: BirkaTokens.sizeBadge,
              minHeight: BirkaTokens.sizeBadge,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: BirkaTokens.spaceXxs,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: const BorderRadius.all(
                Radius.circular(BirkaTokens.radiusPill),
              ),
              // A ring of the background keeps the count off the glass.
              border: Border.all(color: colors.background, width: 2),
            ),
            child: Text(
              '$_shown',
              style: BirkaTextStyles.of(context).label.copyWith(
                color: colors.onAccent,
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
