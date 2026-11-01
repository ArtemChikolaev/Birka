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

  Future<void> _pickLanguage(BuildContext context, Settings settings) async {
    final cubit = context.read<SettingsCubit>();
    final colors = BirkaColors.of(context);
    // In a record, because `null` is a choice here and not a closed sheet.
    final picked = await showModalBottomSheet<(AppLocale?,)>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: colors.background,
      builder: (context) => ChoiceSheet(
        title: t.settings.language,
        children: [
          GlassListGroup(
            children: [
              for (final language in languageChoices)
                GlassListRow(
                  title: languageLabel(language),
                  trailing: language == settings.language
                      ? BirkaIcon(BirkaGlyph.check, color: colors.accent)
                      : null,
                  onTap: () => Navigator.of(context).pop((language,)),
                ),
            ],
          ),
        ],
      ),
    );
    if (picked case (final language,)) await cubit.languageChanged(language);
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
                  title: t.settings.language,
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _widestValue),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            languageLabel(settings.language),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: styles.body.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: BirkaTokens.spaceXs),
                        BirkaIcon(BirkaGlyph.chevron, color: colors.textSubtle),
                      ],
                    ),
                  ),
                  onTap: () => unawaited(_pickLanguage(context, settings)),
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
