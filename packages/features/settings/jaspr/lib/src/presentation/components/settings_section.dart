import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:settings_common/settings_common.dart';

/// The settings of this browser, for the page with everything else.
///
/// It needs a [SettingsCubit] above it.
class SettingsSection extends StatefulComponent {
  /// Creates the section.
  const SettingsSection({super.key});

  @override
  State<SettingsSection> createState() => _SettingsSectionState();

  /// The styles of the section.
  @css
  static List<StyleRule> get styles => [
    css('.settings__group').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.settings__label').styles(raw: {'color': 'var(--color-text-muted)'}),
    css('.settings__value').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'flex': 'none',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.settings__value .birka-icon').styles(
      raw: {'color': 'var(--color-text-subtle)'},
    ),
    css('.settings__check').styles(raw: {'color': 'var(--color-accent)'}),
  ];
}

class _SettingsSectionState extends State<SettingsSection> {
  /// Whether the languages stand open under their row.
  var _choosing = false;

  Component _group(String label, List<Component> rows) {
    return section(classes: 'settings__group', [
      div(classes: 'settings__label', [SectionLabel(label)]),
      GlassListGroup(children: rows),
    ]);
  }

  @override
  Component build(BuildContext context) {
    return BlocBuilder<SettingsCubit, Settings>(
      builder: (context, settings) {
        final cubit = context.read<SettingsCubit>();
        return BirkaColumn(
          children: [
            _group(t.settings.general, [
              GlassListRow(
                title: t.settings.language,
                trailing: span(classes: 'text-body settings__value', [
                  .text(languageLabel(settings.language)),
                  const BirkaIcon(BirkaGlyph.chevron),
                ]),
                onTap: () => setState(() => _choosing = !_choosing),
              ),
              if (_choosing)
                for (final language in languageChoices)
                  GlassListRow(
                    title: languageLabel(language),
                    indented: true,
                    trailing: language == settings.language
                        ? const span(classes: 'settings__check', [
                            BirkaIcon(BirkaGlyph.check),
                          ])
                        : null,
                    onTap: () {
                      setState(() => _choosing = false);
                      unawaited(cubit.languageChanged(language));
                    },
                  ),
            ]),
            _group(t.settings.security, [
              GlassListRow(
                title: t.settings.hideAmounts,
                subtitle: t.settings.onLaunch,
                trailing: BirkaSwitch(
                  value: settings.hideAmountsOnLaunch,
                  label: t.settings.hideAmounts,
                  onChanged: (hide) => unawaited(
                    cubit.hideAmountsOnLaunchChanged(hide: hide),
                  ),
                ),
              ),
            ]),
          ],
        );
      },
    );
  }
}
