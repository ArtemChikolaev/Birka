import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:widgets_common/widgets_common.dart';
import 'package:widgets_flutter/src/presentation/widgets/today_widget_preview.dart';

/// The widgets of the home screen (ADR 0031): what «Сегодня» shows now, the
/// switch of the amounts, how to add a widget, or a button that adds it
/// where the launcher allows, and the other ways in from outside the app.
///
/// It needs a [WidgetsCubit] above it.
class WidgetsPage extends StatelessWidget {
  /// Creates the page.
  const WidgetsPage({required this.onBack, super.key});

  /// Called by the button that goes back.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final cubit = context.read<WidgetsCubit>();
    final android = Theme.of(context).platform == TargetPlatform.android;
    final muted = styles.caption.copyWith(color: colors.textMuted);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocListener<WidgetsCubit, WidgetsState>(
            listenWhen: (previous, current) => current.pinned > previous.pinned,
            listener: (context, state) =>
                showGlassToast(context, t.widgets.pinned),
            child: BlocBuilder<WidgetsCubit, WidgetsState>(
              builder: (context, state) => ListView(
                padding: EdgeInsets.fromLTRB(
                  BirkaTokens.spaceLg,
                  BirkaTokens.spaceXs,
                  BirkaTokens.spaceLg,
                  BirkaTokens.spaceXxl +
                      MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: [
                  BackHeader(
                    label: t.widgets.title,
                    backLabel: t.widgets.back,
                    onBack: onBack,
                  ),
                  const SizedBox(height: BirkaTokens.spaceLg),
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: TodayWidgetPreview(
                        day: state.today,
                        sums: state.sums,
                        android: android,
                      ),
                    ),
                  ),
                  const SizedBox(height: BirkaTokens.spaceSm),
                  Text(
                    android ? t.widgets.kindsAndroid : t.widgets.kinds,
                    textAlign: TextAlign.center,
                    style: muted,
                  ),
                  const SizedBox(height: BirkaTokens.spaceLg),
                  GlassListGroup(
                    children: [
                      GlassListRow(
                        title: t.widgets.sums,
                        trailing: Switch(
                          value: state.sums,
                          onChanged: (shown) =>
                              unawaited(cubit.sumsChanged(shown: shown)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BirkaTokens.spaceXs),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BirkaTokens.spaceXxs,
                    ),
                    child: FadingText(
                      state.sums
                          ? (android
                                ? t.widgets.sumsOnAndroid
                                : t.widgets.sumsOn)
                          : t.widgets.sumsOff,
                      style: muted,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: BirkaTokens.spaceXl),
                  SectionLabel(t.widgets.howTitle, color: colors.textMuted),
                  const SizedBox(height: BirkaTokens.spaceSm),
                  if (android && state.canPin) ...[
                    BirkaButton(
                      label: t.widgets.pin,
                      onPressed: () => unawaited(cubit.pin()),
                    ),
                    const SizedBox(height: BirkaTokens.spaceSm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BirkaTokens.spaceXxs,
                      ),
                      child: Text(t.widgets.pinNote, style: muted),
                    ),
                  ] else
                    GlassListGroup(
                      children: [
                        for (final (index, step)
                            in (android ? t.widgets.howAndroid : t.widgets.how)
                                .indexed)
                          _Step(number: index + 1, text: step),
                      ],
                    ),
                  const SizedBox(height: BirkaTokens.spaceXl),
                  SectionLabel(t.widgets.fasterTitle, color: colors.textMuted),
                  const SizedBox(height: BirkaTokens.spaceSm),
                  GlassListGroup(
                    children: [
                      _Way(
                        glyph: BirkaGlyph.more,
                        title: t.widgets.iconTitle,
                        text: t.widgets.iconText,
                      ),
                      if (android)
                        _Way(
                          glyph: BirkaGlyph.minus,
                          title: t.widgets.shortcutTitle,
                          text: t.widgets.shortcutText,
                        )
                      else ...[
                        _Way(
                          glyph: BirkaGlyph.plus,
                          title: t.widgets.controlTitle,
                          text: t.widgets.controlText,
                        ),
                        _Way(
                          glyph: BirkaGlyph.wave,
                          title: t.widgets.siriTitle,
                          text: t.widgets.siriText,
                        ),
                      ],
                    ],
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

/// A step of adding a widget, by its number.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BirkaTokens.spaceMd,
        vertical: BirkaTokens.spaceSm,
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: styles.caption.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: BirkaTokens.spaceSm),
          Expanded(
            child: Text(
              text,
              style: styles.body.copyWith(color: colors.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Another way into Birka from outside, which the page only names.
class _Way extends StatelessWidget {
  const _Way({required this.glyph, required this.title, required this.text});

  final BirkaGlyph glyph;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return GlassListRow(
      leading: ExcludeSemantics(
        child: GlyphBadge(glyph: glyph, color: colors.accent),
      ),
      title: title,
      subtitle: text,
      subtitleLines: 2,
    );
  }
}
