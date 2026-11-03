import 'package:design_tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// The motion of the app: the durations and curves of the tokens, and
/// whether the system asks for less of it.
abstract final class BirkaMotion {
  /// `duration.fast`: small things, such as a chip that lights up.
  static const Duration fast = Duration(
    milliseconds: BirkaTokens.durationFastMs,
  );

  /// `duration.base`: a page that closes.
  static const Duration base = Duration(
    milliseconds: BirkaTokens.durationBaseMs,
  );

  /// `duration.slow`: a page that opens.
  static const Duration slow = Duration(
    milliseconds: BirkaTokens.durationSlowMs,
  );

  /// `duration.roll`: digits that roll to a new figure.
  static const Duration roll = Duration(
    milliseconds: BirkaTokens.durationRollMs,
  );

  /// `duration.zoom`: a card that grows into its page.
  static const Duration zoom = Duration(
    milliseconds: BirkaTokens.durationZoomMs,
  );

  /// `duration.spring`: something that settles with a bounce.
  static const Duration spring = Duration(
    milliseconds: BirkaTokens.durationSpringMs,
  );

  /// `easing.standard`.
  static final Curve standardCurve = _cubic(BirkaTokens.easingStandard);

  /// `easing.spring`, which overshoots a little.
  static final Curve springCurve = _cubic(BirkaTokens.easingSpring);

  /// `easing.fade`, for opacity.
  static final Curve fadeCurve = _cubic(BirkaTokens.easingFade);

  /// Whether the system asks for less motion: Reduce Motion on iOS, removed
  /// animations on Android. Things then fade instead of moving.
  static bool reduced(BuildContext context) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;

  static Curve _cubic(List<double> points) =>
      Cubic(points[0], points[1], points[2], points[3]);
}
