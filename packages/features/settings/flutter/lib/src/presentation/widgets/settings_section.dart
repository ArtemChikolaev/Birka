import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';

/// The settings of this device, for the tab with everything else.
///
/// It needs a [SettingsCubit] above it.
class SettingsSection extends StatelessWidget {
  /// Creates the section.
  const SettingsSection({super.key});

  /// How far the value of a row reaches, so that it leaves room for the title.
  static const double _widestValue = 180;

  /// Asks for one of [choices], and calls [onPicked] with it.
  Future<void> _pick<T>(
    BuildContext context, {
    required String title,
    required List<T> choices,
    required T selected,
    required String Function(T) labelOf,
    required Future<void> Function(T) onPicked,
  }) async {
    final colors = BirkaColors.of(context);
    // In a record, because `null` is a choice here and not a closed sheet.
    final picked = await showModalBottomSheet<(T,)>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: colors.background,
      builder: (context) => ChoiceSheet(
        title: title,
        children: [
          GlassListGroup(
            children: [
              for (final choice in choices)
                GlassListRow(
                  title: labelOf(choice),
                  trailing: choice == selected
                      ? BirkaIcon(BirkaGlyph.check, color: colors.accent)
                      : null,
                  onTap: () => Navigator.of(context).pop((choice,)),
                ),
            ],
          ),
        ],
      ),
    );
    if (picked case (final choice,)) await onPicked(choice);
  }

  Widget _value(BuildContext context, String text) {
    final colors = BirkaColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _widestValue),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BirkaTextStyles.of(
                context,
              ).body.copyWith(color: colors.textMuted),
            ),
          ),
          const SizedBox(width: BirkaTokens.spaceXxs),
          BirkaIcon(BirkaGlyph.chevron, size: 18, color: colors.textSubtle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return BlocBuilder<SettingsCubit, Settings>(
      builder: (context, settings) {
        final cubit = context.read<SettingsCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionLabel(t.settings.general, color: colors.textMuted),
            const SizedBox(height: BirkaTokens.spaceXs),
            GlassListGroup(
              children: [
                GlassListRow(
                  title: t.settings.baseCurrency,
                  trailing: _value(
                    context,
                    baseCurrencyLabel(settings.baseCurrency),
                  ),
                  onTap: () => unawaited(
                    _pick<Currency?>(
                      context,
                      title: t.settings.baseCurrency,
                      choices: baseCurrencyChoices,
                      selected: settings.baseCurrency,
                      labelOf: baseCurrencyLabel,
                      onPicked: cubit.baseCurrencyChanged,
                    ),
                  ),
                ),
                GlassListRow(
                  title: t.settings.language,
                  trailing: _value(context, languageLabel(settings.language)),
                  onTap: () => unawaited(
                    _pick<AppLocale?>(
                      context,
                      title: t.settings.language,
                      choices: languageChoices,
                      selected: settings.language,
                      labelOf: languageLabel,
                      onPicked: cubit.languageChanged,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BirkaTokens.spaceLg),
            SectionLabel(t.settings.security, color: colors.textMuted),
            const SizedBox(height: BirkaTokens.spaceXs),
            GlassListGroup(
              children: [
                GlassListRow(
                  title: t.settings.hideAmounts,
                  subtitle: t.settings.onLaunch,
                  trailing: Switch(
                    value: settings.hideAmountsOnLaunch,
                    onChanged: (hide) =>
                        cubit.hideAmountsOnLaunchChanged(hide: hide),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BirkaTokens.spaceMd),
            Text(
              '${t.settings.ratesCredit}: cbr-xml-daily.ru',
              style: styles.caption.copyWith(color: colors.textSubtle),
            ),
          ],
        );
      },
    );
  }
}
