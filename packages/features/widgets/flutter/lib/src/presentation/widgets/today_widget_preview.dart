import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:home_screen/home_screen.dart';
import 'package:l10n/l10n.dart';

/// «Сегодня» in the middle size, as the home screen shows it: the widget of
/// iOS, or 4 × 2 cells of Android with [android] (ADR 0031). It draws [day],
/// or what the widget says without figures, and hides the amounts the way
/// the app does when [sums] is off or the amounts of the app are hidden.
class TodayWidgetPreview extends StatefulWidget {
  /// Creates the preview of [day].
  const TodayWidgetPreview({
    required this.day,
    required this.sums,
    this.android = false,
    super.key,
  });

  /// The figures of today, or `null` while there are none.
  final WidgetDay? day;

  /// Whether the widgets show amounts.
  final bool sums;

  /// Whether it draws the widget of Android.
  final bool android;

  @override
  State<TodayWidgetPreview> createState() => _TodayWidgetPreviewState();
}

class _TodayWidgetPreviewState extends State<TodayWidgetPreview> {
  final ValueNotifier<bool> _hidden = ValueNotifier(false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _follow();
  }

  @override
  void didUpdateWidget(TodayWidgetPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _follow();
  }

  /// The amounts hide when the widgets hide them or the app does.
  void _follow() => _hidden.value = !widget.sums || HiddenAmounts.of(context);

  @override
  void dispose() {
    _hidden.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final android = widget.android;
    return Semantics(
      label: t.widgets.preview,
      child: ExcludeSemantics(
        child: HiddenAmounts(
          notifier: _hidden,
          child: SizedBox(
            width: android ? 358 : 338,
            height: android ? 176 : 158,
            child: _Body(day: widget.day, android: android),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.day, required this.android});

  final WidgetDay? day;
  final bool android;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final day = this.day;
    final over = day?.kind == WidgetDayKind.over;
    final spentOnly = day?.kind == WidgetDayKind.spent;
    final radius = android ? BirkaTokens.radiusXl : BirkaTokens.radiusLg;
    final muted = styles.caption.copyWith(color: colors.textMuted);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: colors.background,
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.3,
          colors: [colors.ambient, colors.background],
        ),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          android ? BirkaTokens.spaceLg : BirkaTokens.spaceMd,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadingText(
                    (day?.label ?? t.schedules.canSpend).toUpperCase(),
                    style: styles.label.copyWith(color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: BirkaTokens.spaceXxs),
                  AmountText(
                    day?.figure ?? '—',
                    value: day?.value,
                    rise: spentOnly ? AmountRise.bad : AmountRise.good,
                    tone: over ? AmountTone.negative : AmountTone.neutral,
                    style: styles.title,
                  ),
                  FadingText(
                    HiddenAmounts.mask(
                      context,
                      day?.of ?? t.widgets.previewEmpty,
                    ),
                    style: muted,
                    maxLines: 2,
                  ),
                  const Spacer(),
                  if (day != null && !spentOnly) ...[
                    _Bar(share: day.share, over: over),
                    const SizedBox(height: BirkaTokens.spaceXs),
                    FadingText(
                      HiddenAmounts.mask(context, day.spent),
                      style: muted,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: BirkaTokens.spaceMd),
            SizedBox(
              width: android ? 116 : 104,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Pill(
                    glyph: BirkaGlyph.minus,
                    label: t.widgets.expense,
                    main: true,
                    height: android ? 56 : 52,
                  ),
                  const SizedBox(height: BirkaTokens.spaceSm),
                  _Pill(
                    glyph: BirkaGlyph.plus,
                    label: t.widgets.income,
                    main: false,
                    height: android ? 56 : 52,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The part of the share of the day that is spent.
class _Bar extends StatelessWidget {
  const _Bar({required this.share, required this.over});

  final double share;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final reduced = BirkaMotion.reduced(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(BirkaTokens.radiusPill),
      child: SizedBox(
        height: 6,
        child: ColoredBox(
          color: colors.hairline,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: reduced ? Duration.zero : BirkaMotion.roll,
              curve: BirkaMotion.standardCurve,
              widthFactor: share.clamp(0, 1),
              heightFactor: 1,
              child: AnimatedContainer(
                duration: BirkaMotion.base,
                color: over ? colors.negative : colors.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A button of the widget, which the preview only shows.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.glyph,
    required this.label,
    required this.main,
    required this.height,
  });

  final BirkaGlyph glyph;
  final String label;
  final bool main;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final ink = main ? colors.onAccent : colors.text;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: main ? colors.accent : colors.surfaceRaised,
        borderRadius: BorderRadius.circular(BirkaTokens.radiusPill),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BirkaIcon(glyph, size: 18, color: ink),
          const SizedBox(width: BirkaTokens.spaceXxs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: styles.bodyStrong.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}
