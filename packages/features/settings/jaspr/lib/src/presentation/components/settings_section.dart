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
    css('.settings__group .glass-row').styles(raw: {'gap': 'var(--space-xs)'}),
    css('.settings__label').styles(raw: {'color': 'var(--color-text-muted)'}),
    css('.settings__value').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'flex': 'none',
        'gap': 'var(--space-xxs)',
      },
    ),
    css('.settings__value .birka-icon').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'height': '18px',
        'width': '18px',
      },
    ),
    css('.settings__check').styles(raw: {'color': 'var(--color-accent)'}),
  ];
}

/// The choice that stands open.
enum _Choice { baseCurrency, language }

class _SettingsSectionState extends State<SettingsSection> {
  /// The choice whose options stand open under its row.
  _Choice? _open;

  Component _group(String label, List<Component> rows) {
    return section(classes: 'settings__group', [
      div(classes: 'settings__label', [SectionLabel(label)]),
      GlassListGroup(children: rows),
    ]);
  }

  /// A row with its value, and under it [choices] while it stands open.
  List<Component> _choice<T>({
    required _Choice choice,
    required String title,
    required List<T> choices,
    required T selected,
    required String Function(T) labelOf,
    required Future<void> Function(T) onPicked,
  }) {
    return [
      GlassListRow(
        title: title,
        trailing: span(classes: 'text-body settings__value', [
          .text(labelOf(selected)),
          const BirkaIcon(BirkaGlyph.chevron),
        ]),
        onTap: () => setState(() => _open = _open == choice ? null : choice),
      ),
      if (_open == choice)
        for (final option in choices)
          GlassListRow(
            title: labelOf(option),
            indented: true,
            trailing: option == selected
                ? const span(classes: 'settings__check', [
                    BirkaIcon(BirkaGlyph.check),
                  ])
                : null,
            onTap: () {
              setState(() => _open = null);
              unawaited(onPicked(option));
            },
          ),
    ];
  }

  @override
  Component build(BuildContext context) {
    return BlocBuilder<SettingsCubit, Settings>(
      builder: (context, settings) {
        final cubit = context.read<SettingsCubit>();
        return BirkaColumn(
          children: [
            _group(t.settings.general, [
              ..._choice<Currency?>(
                choice: _Choice.baseCurrency,
                title: t.settings.baseCurrency,
                choices: baseCurrencyChoices,
                selected: settings.baseCurrency,
                labelOf: baseCurrencyLabel,
                onPicked: cubit.baseCurrencyChanged,
              ),
              ..._choice<AppLocale?>(
                choice: _Choice.language,
                title: t.settings.language,
                choices: languageChoices,
                selected: settings.language,
                labelOf: languageLabel,
                onPicked: cubit.languageChanged,
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
