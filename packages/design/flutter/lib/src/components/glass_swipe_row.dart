import 'package:design_flutter/src/components/birka_icon.dart';
import 'package:design_flutter/src/theme/birka_colors.dart';
import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// A button behind a [GlassSwipeRow].
@immutable
final class GlassSwipeAction {
  /// Creates a button with [glyph]. Screen readers read [label].
  const GlassSwipeAction({
    required this.glyph,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  /// What the button shows.
  final BirkaGlyph glyph;

  /// What the button does, for screen readers.
  final String label;

  /// Called on a tap.
  final VoidCallback onPressed;

  /// Whether the action takes something away, in the color of a loss.
  final bool danger;
}

/// A row that slides to the left and shows [actions] behind it.
///
/// A tap anywhere else closes it. Screen readers get the same actions without
/// the swipe.
class GlassSwipeRow extends StatefulWidget {
  /// Creates a row with [child] on top of [actions].
  const GlassSwipeRow({required this.actions, required this.child, super.key});

  /// The buttons behind the row, from left to right.
  final List<GlassSwipeAction> actions;

  /// The row itself.
  final Widget child;

  @override
  State<GlassSwipeRow> createState() => _GlassSwipeRowState();
}

class _GlassSwipeRowState extends State<GlassSwipeRow>
    with SingleTickerProviderStateMixin {
  static const double _buttonWidth = 60;
  static const double _buttonHeight = BirkaTokens.sizeTouchTarget;

  /// A flick faster than this opens or closes the row, however short it is.
  static const double _flick = 400;

  late final _opening = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: BirkaTokens.durationBaseMs),
  );

  double get _width =>
      widget.actions.length * (_buttonWidth + BirkaTokens.spaceXs) +
      BirkaTokens.spaceXs;

  @override
  void dispose() {
    _opening.dispose();
    super.dispose();
  }

  void _dragged(DragUpdateDetails details) {
    _opening.value -= details.primaryDelta! / _width;
  }

  void _released(DragEndDetails details) {
    final speed = details.primaryVelocity ?? 0;
    final open = speed.abs() > _flick ? speed < 0 : _opening.value > 0.5;
    _animate(open: open);
  }

  void _close() => _animate(open: false);

  void _animate({required bool open}) {
    _opening.animateTo(open ? 1 : 0, curve: Curves.easeOutCubic).ignore();
  }

  void _pressed(GlassSwipeAction action) {
    _close();
    action.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) {
        if (_opening.value > 0) _close();
      },
      child: MergeSemantics(
        child: Semantics(
          customSemanticsActions: {
            for (final action in widget.actions)
              CustomSemanticsAction(label: action.label): action.onPressed,
          },
          child: ClipRect(
            child: GestureDetector(
              onHorizontalDragUpdate: _dragged,
              onHorizontalDragEnd: _released,
              onHorizontalDragCancel: _close,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: Align(
                        alignment: Alignment.centerRight,
                        // Only the room that the row leaves shows the buttons,
                        // since glass lets everything behind it through.
                        child: ClipRect(
                          child: AnimatedBuilder(
                            animation: _opening,
                            builder: (context, child) => Align(
                              alignment: Alignment.centerRight,
                              widthFactor: _opening.value,
                              child: child,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: BirkaTokens.spaceXs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final action in widget.actions)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: BirkaTokens.spaceXs,
                                      ),
                                      child: _Button(
                                        action: action,
                                        width: _buttonWidth,
                                        height: _buttonHeight,
                                        onPressed: () => _pressed(action),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _opening,
                    child: widget.child,
                    builder: (context, child) {
                      final open = _opening.value > 0;
                      return Transform.translate(
                        offset: Offset(-_opening.value * _width, 0),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: open ? _close : null,
                          child: IgnorePointer(ignoring: open, child: child),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.action,
    required this.width,
    required this.height,
    required this.onPressed,
  });

  final GlassSwipeAction action;
  final double width;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: action.danger
              ? colors.negative.withValues(alpha: 0.16)
              : colors.surfaceRaised,
          borderRadius: const BorderRadius.all(
            Radius.circular(BirkaTokens.radiusSm),
          ),
        ),
        child: BirkaIcon(
          action.glyph,
          size: 20,
          color: action.danger ? colors.negative : colors.text,
        ),
      ),
    );
  }
}
