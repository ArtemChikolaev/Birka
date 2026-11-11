import 'package:birka_web/app/browser.dart';
import 'package:jaspr/jaspr.dart';

/// Follows whether the window is wide, where a page lays out side by side
/// (ADR 0008, point 11), and builds the island again when that changes.
mixin WideWindow<T extends StatefulComponent> on State<T> {
  var _wide = false;
  void Function()? _stopWatchingWidth;

  /// Whether the window is wide.
  bool get wide => _wide;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    _wide = wideScreen;
    _stopWatchingWidth = watchWideScreen(
      ({required wide}) => setState(() => _wide = wide),
    );
  }

  @override
  void dispose() {
    _stopWatchingWidth?.call();
    super.dispose();
  }
}
