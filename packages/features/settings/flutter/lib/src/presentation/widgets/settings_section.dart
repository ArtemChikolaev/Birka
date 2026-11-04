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

  /// Asks for one of [choices], and calls [onPicked] with it.
  Future<void> _pick<T>(
    BuildContext context, {
    required String title,
    required List<T> choices,
    required T selected,
    required String Function(T) labelOf,
    required Future<void> Function(T) onPicked,
  }) async {
    final picked = await showChoiceSheet<T>(
      context,
      title: title,
      choices: choices,
      selected: selected,
      labelOf: labelOf,
    );
    if (picked case (final choice,)) await onPicked(choice);
  }

  @override
  Widget build(BuildContext context) {
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
                  trailing: GlassListValue(
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
                  trailing: GlassListValue(languageLabel(settings.language)),
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
          ],
        );
      },
    );
  }
}
