import 'dart:async';
import 'dart:math';

import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/components/glass_nav_bar.dart';
import 'package:design_flutter/src/components/glass_surface.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:design_flutter/src/theme/birka_text_styles.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// A short message on glass: what came of an action, after a check mark, or
/// what went wrong, after a cross.
class GlassToast extends StatelessWidget {
  /// Creates a message that says [text].
  const GlassToast(this.text, {this.trouble = false, super.key});

  /// What it says.
  final String text;

  /// Whether it says that something went wrong.
  final bool trouble;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return GlassSurface(
      child: Row(
        children: [
          BirkaIcon(
            trouble ? BirkaGlyph.close : BirkaGlyph.check,
            size: 20,
            color: trouble ? colors.negative : colors.accent,
          ),
          const SizedBox(width: BirkaTokens.spaceSm),
          Expanded(
            child: Text(
              text,
              style: BirkaTextStyles.of(
                context,
              ).body.copyWith(color: colors.text),
            ),
          ),
        ],
      ),
    );
  }
}

// The toast on screen, which a new one takes the place of.
OverlayEntry? _shown;

/// Shows [text] in a [GlassToast] over the bottom of the screen for a few
/// seconds, in place of the toast before it, and reads it out to screen
/// readers. Shown from a tab, it stands above the bar of the tabs
/// ([GlassNavBarSpace]). It comes up from below with a little bounce over
/// `duration.spring` and goes a little down as it fades over
/// `duration.base`; when the system asks for less motion, it only fades.
/// It needs an [Overlay], such as that of a navigator.
void showGlassToast(BuildContext context, String text, {bool trouble = false}) {
  _shown?.remove();
  final bar = GlassNavBarSpace.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _Toast(
      text: text,
      trouble: trouble,
      bar: bar,
      onGone: () {
        if (!identical(_shown, entry)) return;
        _shown = null;
        entry.remove();
      },
    ),
  );
  _shown = entry;
  Overlay.of(context).insert(entry);
  unawaited(
    SemanticsService.sendAnnouncement(
      View.of(context),
      text,
      Directionality.of(context),
    ),
  );
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.text,
    required this.trouble,
    required this.bar,
    required this.onGone,
  });

  final String text;
  final bool trouble;

  /// How far the bar of the tabs reaches up, or 0 without one.
  final double bar;
  final VoidCallback onGone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  /// How long the toast stays once it has come in.
  static const _stay = Duration(seconds: 4);

  /// How far below its place it comes from, and how far it goes as it fades.
  static const double _from = 120;
  static const double _away = BirkaTokens.spaceMd;

  late final AnimationController _shown =
      AnimationController(
          vsync: this,
          duration: BirkaMotion.spring,
          reverseDuration: BirkaMotion.base,
        )
        ..addStatusListener(_moved)
        ..forward();

  Timer? _stayed;

  void _moved(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        _stayed = Timer(_stay, () => unawaited(_shown.reverse()));
      case AnimationStatus.dismissed:
        widget.onGone();
      case AnimationStatus.forward || AnimationStatus.reverse:
        break;
    }
  }

  @override
  void dispose() {
    _stayed?.cancel();
    _shown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduced = BirkaMotion.reduced(context);
    return Positioned(
      left: BirkaTokens.spaceLg + media.padding.left,
      right: BirkaTokens.spaceLg + media.padding.right,
      bottom: max(
        BirkaTokens.spaceLg +
            max(media.viewPadding.bottom, media.viewInsets.bottom),
        widget.bar + BirkaTokens.spaceSm,
      ),
      // The overlay stands outside the material of the pages, so the toast
      // gives its text the style that a page would.
      child: DefaultTextStyle(
        style: BirkaTextStyles.of(
          context,
        ).body.copyWith(color: BirkaColors.of(context).text),
        child: Semantics(
          liveRegion: true,
          child: AnimatedBuilder(
            animation: _shown,
            builder: (context, child) {
              final moved = _shown.value;
              final going = _shown.status == AnimationStatus.reverse;
              final double offset;
              final double opacity;
              if (reduced) {
                offset = 0;
                opacity = BirkaMotion.fadeCurve.transform(moved);
              } else if (going) {
                offset = BirkaMotion.standardCurve.transform(1 - moved) * _away;
                opacity = BirkaMotion.fadeCurve.transform(moved);
              } else {
                // It shows over the first `duration.base` of its rise.
                final ms = moved * BirkaMotion.spring.inMilliseconds;
                offset = (1 - BirkaMotion.springCurve.transform(moved)) * _from;
                opacity = BirkaMotion.fadeCurve.transform(
                  (ms / BirkaMotion.base.inMilliseconds).clamp(0, 1),
                );
              }
              return Transform.translate(
                offset: Offset(0, offset),
                child: Opacity(opacity: opacity, child: child),
              );
            },
            child: GlassToast(widget.text, trouble: widget.trouble),
          ),
        ),
      ),
    );
  }
}
