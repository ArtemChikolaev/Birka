import 'dart:async';
import 'dart:math' as math;

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_flutter/src/presentation/widgets/receipt_twice_sheet.dart';

/// What stands in place of the camera in a test: it gives the codes that it
/// "sees" to [onCode].
typedef ReceiptPreview =
    Widget Function(BuildContext context, ValueChanged<String> onCode);

/// The scanner of the QR codes of receipts (ADR 0032): the camera fills the
/// screen and a frame shows where to hold the code.
///
/// While it looks, the corners of the frame breathe. A code that is not a
/// receipt flashes them coral and changes the hint, and the scanner keeps
/// looking. A receipt snaps the frame to the code, turns it green with a
/// check and closes the scanner with it a moment later; a receipt that the
/// ledger already has opens a sheet instead. Without the camera it says why
/// and offers the settings or quick add by hand.
///
/// It needs a [ReceiptScanCubit] above it.
class ReceiptScannerPage extends StatefulWidget {
  /// Creates the scanner.
  const ReceiptScannerPage({
    required this.onClose,
    required this.onOpenOperation,
    required this.onOpenSettings,
    @visibleForTesting this.preview,
    super.key,
  });

  /// Closes the scanner with the receipt that it read, or with none.
  final ValueChanged<ReceiptQr?> onClose;

  /// Opens the operation that the ledger already made from a receipt.
  final ValueChanged<String> onOpenOperation;

  /// Opens the settings of the app, where the camera can be allowed.
  final VoidCallback onOpenSettings;

  /// What stands in place of the camera in a test.
  final ReceiptPreview? preview;

  @override
  State<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

enum _Camera { working, refused, failed }

class _ReceiptScannerPageState extends State<ReceiptScannerPage>
    with TickerProviderStateMixin {
  /// How long the read receipt stays on the screen before the scanner closes.
  static const Duration _shown = Duration(milliseconds: 700);

  /// How long the corners stay coral after a code that is not a receipt.
  static const Duration _flashing = Duration(milliseconds: 600);

  /// One breath of the corners while the scanner looks.
  static const Duration _breathing = Duration(milliseconds: 1200);

  MobileScannerController? _controller;
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: _breathing,
  );
  late final AnimationController _snap = AnimationController(
    vsync: this,
    duration: BirkaMotion.spring,
  );
  _Camera _camera = _Camera.working;
  bool _torch = false;
  bool _torchAvailable = false;
  bool _flash = false;
  bool _reduced = false;
  Timer? _flashTimer;
  Timer? _closeTimer;
  bool _closed = false;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    if (widget.preview == null) {
      _controller = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
      )..addListener(_followCamera);
      // The camera of the package restarts on its own only while it is
      // allowed; one allowed in the settings meanwhile starts here.
      _lifecycle = AppLifecycleListener(onResume: _retry);
    }
  }

  void _retry() {
    final controller = _controller;
    if (controller == null || _camera == _Camera.working) return;
    unawaited(controller.start().catchError((Object _) {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = BirkaMotion.reduced(context);
    if (_reduced) {
      _breath.value = 0;
      _breath.stop();
    } else if (!_breath.isAnimating && _snap.value == 0) {
      unawaited(_breath.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _closeTimer?.cancel();
    _lifecycle?.dispose();
    _breath.dispose();
    _snap.dispose();
    final controller = _controller?..removeListener(_followCamera);
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  void _followCamera() {
    final value = _controller?.value;
    if (value == null || !mounted) return;
    final camera = switch (value.error?.errorCode) {
      null => _Camera.working,
      MobileScannerErrorCode.permissionDenied => _Camera.refused,
      _ => _Camera.failed,
    };
    final torch = value.torchState == TorchState.on;
    final available = value.torchState != TorchState.unavailable;
    if (camera != _camera || torch != _torch || available != _torchAvailable) {
      setState(() {
        _camera = camera;
        _torch = torch;
        _torchAvailable = available;
      });
    }
  }

  void _seen(BarcodeCapture capture) {
    final cubit = context.read<ReceiptScanCubit>();
    for (final barcode in capture.barcodes) {
      final text = barcode.rawValue;
      if (text != null) unawaited(cubit.codeSeen(text));
    }
  }

  Future<void> _react(BuildContext context, ReceiptScanState state) async {
    switch (state.status) {
      case ReceiptScanStatus.looking:
        break;
      case ReceiptScanStatus.notReceipt:
        _flashTimer?.cancel();
        setState(() => _flash = true);
        _flashTimer = Timer(_flashing, () {
          if (mounted) setState(() => _flash = false);
        });
      case ReceiptScanStatus.read:
        unawaited(HapticFeedback.mediumImpact());
        _found();
        final read = state.read;
        _closeTimer = Timer(_shown, () => _close(read));
      case ReceiptScanStatus.twice:
        unawaited(HapticFeedback.mediumImpact());
        _found();
        final recorded = state.recorded;
        if (recorded == null) return;
        final cubit = context.read<ReceiptScanCubit>();
        final choice = await showReceiptTwice(context, recorded);
        if (!mounted) return;
        if (choice == ReceiptTwiceChoice.open) {
          widget.onOpenOperation(recorded.id);
        } else {
          _lookAgain();
          cubit.lookAgain();
        }
    }
  }

  /// Leaves the scanner once: ✕ or «Ввести вручную» in the moment a read
  /// shows must not let the read close quick add under it as well.
  void _close(ReceiptQr? read) {
    _closeTimer?.cancel();
    if (_closed || !mounted) return;
    _closed = true;
    widget.onClose(read);
  }

  void _found() {
    _flashTimer?.cancel();
    _flash = false;
    _breath.stop();
    if (_reduced) {
      _snap.value = 1;
    } else {
      unawaited(_snap.forward());
    }
  }

  void _lookAgain() {
    if (_reduced) {
      _snap.value = 0;
    } else {
      unawaited(_snap.reverse());
      unawaited(_breath.repeat(reverse: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return BlocListener<ReceiptScanCubit, ReceiptScanState>(
      listener: _react,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // The camera stays under the page without it, so that it can
            // start again once it is allowed.
            _preview(context),
            if (_camera == _Camera.working) ...[
              _Frame(
                breath: _breath,
                snap: _snap,
                flash: _flash,
                reduced: _reduced,
              ),
              _ReadLine(snap: _snap),
            ] else
              ColoredBox(color: colors.background),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BirkaTokens.spaceLg,
                  BirkaTokens.spaceXs,
                  BirkaTokens.spaceLg,
                  BirkaTokens.spaceLg,
                ),
                child: Column(
                  children: [
                    _TopBar(onClose: () => _close(null)),
                    if (_camera == _Camera.working) ...[
                      const Spacer(),
                      _Bottom(
                        torch: _torchAvailable ? _torch : null,
                        onTorch: () => unawaited(_controller?.toggleTorch()),
                        onByHand: () => _close(null),
                      ),
                    ] else
                      Expanded(
                        child: _NoCamera(
                          refused: _camera == _Camera.refused,
                          onOpenSettings: widget.onOpenSettings,
                          onByHand: () => _close(null),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(BuildContext context) {
    final preview = widget.preview;
    if (preview != null) {
      final cubit = context.read<ReceiptScanCubit>();
      return preview(context, (text) => unawaited(cubit.codeSeen(text)));
    }
    return MobileScanner(
      controller: _controller,
      onDetect: _seen,
      // The page says what went wrong itself.
      errorBuilder: (context, error) => const SizedBox.shrink(),
      placeholderBuilder: (context) => const ColoredBox(color: Colors.black),
    );
  }
}

/// Where the frame stands in [size]: a square in the middle, a little above
/// the centre, that shrinks onto the code as [snap] goes to one.
Rect _frameIn(Size size, double snap) {
  final side = math.min(250, size.width - 2 * BirkaTokens.spaceXxl);
  final shown = side * (1 - 0.336 * snap);
  final centre = Offset(size.width / 2, size.height * 0.45);
  return Rect.fromCenter(center: centre, width: shown, height: shown);
}

/// The frame of the scanner: the rest of the screen dims around it and its
/// corners breathe, flash and snap.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.breath,
    required this.snap,
    required this.flash,
    required this.reduced,
  });

  final Animation<double> breath;
  final Animation<double> snap;
  final bool flash;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final settle = CurvedAnimation(
      parent: snap,
      curve: reduced ? BirkaMotion.fadeCurve : BirkaMotion.springCurve,
    );
    return IgnorePointer(
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: flash ? colors.negative : colors.text),
        duration: BirkaMotion.fast,
        builder: (context, ink, _) => AnimatedBuilder(
          animation: Listenable.merge([breath, settle]),
          builder: (context, _) => CustomPaint(
            painter: _FramePainter(
              snap: settle.value,
              breath: Curves.easeInOut.transform(breath.value),
              ink: Color.lerp(ink ?? colors.text, colors.accent, snap.value)!,
            ),
          ),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter({
    required this.snap,
    required this.breath,
    required this.ink,
  });

  final double snap;
  final double breath;
  final Color ink;

  static const double _radius = 28;
  static const double _corner = 36;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = _frameIn(size, snap);
    final grown = rect.inflate(rect.width * 0.0125 * breath * (1 - snap));
    final hole = RRect.fromRectAndRadius(
      grown,
      const Radius.circular(_radius),
    );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(hole),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.5 + 0.12 * snap),
    );
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final r = grown;
    const arc = Radius.circular(_radius);
    for (final (corner, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      final path = Path()
        ..moveTo(corner.dx, corner.dy + dy * _corner)
        ..lineTo(corner.dx, corner.dy + dy * _radius)
        ..arcToPoint(
          Offset(corner.dx + dx * _radius, corner.dy),
          radius: arc,
          clockwise: dx * dy > 0,
        )
        ..lineTo(corner.dx + dx * _corner, corner.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.snap != snap || old.breath != breath || old.ink != ink;
}

/// The check over the code and the line of the receipt under the frame,
/// which come once the scanner reads a receipt.
class _ReadLine extends StatelessWidget {
  const _ReadLine({required this.snap});

  final Animation<double> snap;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final read = context.select<ReceiptScanCubit, ReceiptQr?>(
      (cubit) => cubit.state.status == ReceiptScanStatus.read
          ? cubit.state.read
          : null,
    );
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rect = _frameIn(constraints.biggest, 1);
          return AnimatedBuilder(
            animation: snap,
            builder: (context, _) {
              final check = Curves.easeOut.transform(
                ((snap.value - 0.2) / 0.8).clamp(0, 1),
              );
              return Stack(
                children: [
                  Positioned.fromRect(
                    rect: Rect.fromCenter(
                      center: rect.center,
                      width: 64,
                      height: 64,
                    ),
                    child: Opacity(
                      opacity: check,
                      child: Transform.scale(
                        scale: 0.4 + 0.6 * check,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: BirkaIcon(
                              BirkaGlyph.check,
                              size: 30,
                              color: colors.onAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (read != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: rect.bottom + BirkaTokens.spaceXl,
                      child: Opacity(
                        opacity: check,
                        child: Transform.translate(
                          offset: Offset(0, 24 * (1 - check)),
                          child: Center(
                            child: GlassSurface(
                              padding: const EdgeInsets.symmetric(
                                horizontal: BirkaTokens.spaceMd,
                                vertical: BirkaTokens.spaceSm,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  BirkaIcon(
                                    BirkaGlyph.receipt,
                                    size: 20,
                                    color: colors.accent,
                                  ),
                                  const SizedBox(width: BirkaTokens.spaceXs),
                                  Flexible(
                                    child: Text(
                                      _readLine(read),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: styles.bodyStrong.copyWith(
                                        color: colors.text,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static String _readLine(ReceiptQr read) {
    final today = CivilDate.of(DateTime.now());
    final day = dayHeading(CivilDate.of(read.at), today: today);
    final sum = read.receipt.kind.spends ? -read.sum : read.sum;
    return '${signedAmountLabel(sum)} · $day, ${timeLabel(read.at)}';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 44),
        Expanded(
          child: Center(
            child: SectionLabel(
              t.transactions.receipt.title,
              color: BirkaColors.of(context).textSecondary,
            ),
          ),
        ),
        GlassIconButton(
          glyph: BirkaGlyph.close,
          label: t.app.close,
          glass: false,
          onPressed: onClose,
        ),
      ],
    );
  }
}

/// The hint, the torch and the way back to quick add by hand.
class _Bottom extends StatelessWidget {
  const _Bottom({
    required this.torch,
    required this.onTorch,
    required this.onByHand,
  });

  /// Whether the torch is on, or `null` when the camera has none.
  final bool? torch;
  final VoidCallback onTorch;
  final VoidCallback onByHand;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final status = context.select<ReceiptScanCubit, ReceiptScanStatus>(
      (cubit) => cubit.state.status,
    );
    final words = t.transactions.receipt;
    final (hint, line) = switch (status) {
      ReceiptScanStatus.notReceipt => (
        words.notReceipt,
        words.notReceiptHint,
      ),
      ReceiptScanStatus.read ||
      ReceiptScanStatus.twice => (words.read, words.readHint),
      ReceiptScanStatus.looking => (words.look, words.lookHint),
    };
    final torch = this.torch;
    return Column(
      children: [
        FadingText(
          hint,
          textAlign: TextAlign.center,
          style: styles.bodyStrong.copyWith(color: colors.text),
        ),
        const SizedBox(height: BirkaTokens.spaceXxs),
        FadingText(
          line,
          textAlign: TextAlign.center,
          style: styles.caption.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: BirkaTokens.spaceXl),
        Row(
          children: [
            if (torch != null) ...[
              Semantics(
                toggled: torch,
                child: GlassIconButton(
                  glyph: BirkaGlyph.torch,
                  label: words.torch,
                  onPressed: onTorch,
                ),
              ),
              const SizedBox(width: BirkaTokens.spaceSm),
            ],
            Expanded(
              child: BirkaButton(
                label: words.byHand,
                quiet: true,
                onPressed: onByHand,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// What the scanner says without the camera: refused, or not working.
class _NoCamera extends StatelessWidget {
  const _NoCamera({
    required this.refused,
    required this.onOpenSettings,
    required this.onByHand,
  });

  final bool refused;
  final VoidCallback onOpenSettings;
  final VoidCallback onByHand;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final words = t.transactions.receipt;
    return Column(
      children: [
        const Spacer(flex: 2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: BorderRadius.circular(BirkaTokens.radiusLg),
          ),
          child: SizedBox.square(
            dimension: 72,
            child: Center(
              child: BirkaIcon(
                BirkaGlyph.camera,
                size: 32,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceMd),
        Text(
          refused ? words.noCamera : words.cameraFailed,
          textAlign: TextAlign.center,
          style: styles.heading.copyWith(color: colors.text),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        Text(
          refused ? words.noCameraText : words.cameraFailedText,
          textAlign: TextAlign.center,
          style: styles.body.copyWith(color: colors.textMuted),
        ),
        const Spacer(flex: 3),
        if (refused) ...[
          BirkaButton(label: words.openSettings, onPressed: onOpenSettings),
          const SizedBox(height: BirkaTokens.spaceXs),
        ],
        BirkaButton(label: words.byHand, quiet: refused, onPressed: onByHand),
      ],
    );
  }
}
