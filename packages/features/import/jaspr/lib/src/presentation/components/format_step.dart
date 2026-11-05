import 'package:design_jaspr/design_jaspr.dart';
import 'package:import_common/import_common.dart';
import 'package:import_jaspr/src/presentation/components/import_bits.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The second step: the bank that the columns tell, with the columns it
/// knows, and the known formats to pick another.
class FormatStep extends StatelessComponent {
  /// Creates the step of [state].
  const FormatStep({required this.state, super.key});

  /// The import.
  final ImportState state;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<ImportCubit>();
    final layout = state.layout!;
    final format = layout.format;
    final named = [
      for (final column in layout.columns)
        if (column.header.trim().isNotEmpty) column,
    ];
    return div(classes: 'import-stack', [
      div(classes: 'glass import-detected', [
        GlyphBadge(
          glyph: BirkaGlyph.wallet,
          color: format == null
              ? 'var(--color-text-muted)'
              : 'var(--color-accent)',
          size: 44,
        ),
        div(classes: 'import-detected__text', [
          h2(classes: 'text-heading import-detected__title', [
            .text(
              format == null
                  ? t.imports.notKnown
                  : isOwnFormat(format)
                  ? t.imports.looksLikeOwn
                  : t.imports.looksLike(
                      bank: t.imports.formatsOf[format.id] ?? format.id,
                    ),
            ),
          ]),
          p(classes: 'text-body import-detected__line', [
            .text(
              format == null
                  ? t.imports.notKnownText
                  : t.imports.matched(n: layout.known, total: named.length),
            ),
          ]),
          if (format != null)
            ul(classes: 'import-detected__columns', [
              for (final column in named)
                if (layout.roles[column.index] == ColumnRole.skip)
                  li(
                    classes:
                        'text-caption import-column-chip '
                        'import-column-chip--skipped',
                    [
                      .text(
                        t.imports.skipped(header: column.header.trim()),
                      ),
                    ],
                  )
                else
                  li(classes: 'text-caption import-column-chip', [
                    const BirkaIcon(BirkaGlyph.check),
                    .text(column.header.trim()),
                  ]),
            ]),
        ]),
      ]),
      section(classes: 'import-section', [
        SectionLabel(t.imports.formatsTitle),
        div(
          classes: 'import-formats',
          attributes: {
            'role': 'radiogroup',
            'aria-label': t.imports.formatsTitle,
          },
          [
            for (final known in statementFormats)
              GlassOption(
                leading: FormatMark(known),
                title: formatLabel(known),
                tag: t.imports.fileKinds[known.file.name],
                subtitle: t.imports.formatTexts[known.id],
                selected: format?.id == known.id,
                onTap: () => cubit.useFormat(known),
              ),
            // A format of one's own that Birka kept stands here too.
            GlassOption(
              leading: const FormatMark(null),
              title: t.imports.own,
              tag: t.imports.ownTag,
              subtitle: t.imports.ownText,
              selected: format == null || isOwnFormat(format),
              onTap: () => cubit.useFormat(isOwnFormat(format) ? format : null),
            ),
          ],
        ),
      ]),
    ]);
  }

  /// The styles of the step.
  @css
  static List<StyleRule> get styles => [
    css('.import-detected').styles(
      raw: {
        'align-items': 'flex-start',
        'background':
            'linear-gradient(160deg, var(--color-accent-soft) 0%, '
            'var(--color-glass-fill-bottom) 100%)',
        'display': 'flex',
        'gap': 'var(--space-md)',
      },
    ),
    css('.import-detected__text').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
        'min-width': '0',
      },
    ),
    css('.import-detected__title').styles(
      raw: {'color': 'var(--color-text)', 'margin': '0'},
    ),
    css('.import-detected__line').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css('.import-detected__columns').styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs)',
        'list-style': 'none',
        'margin': 'var(--space-xs) 0 0',
        'padding': '0',
      },
    ),
    css('.import-column-chip').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-surface)',
        'border': '1px solid var(--color-hairline)',
        'border-radius': 'var(--radius-pill)',
        'color': 'var(--color-text)',
        'display': 'inline-flex',
        'font-weight': 'var(--font-weight-semibold)',
        'gap': 'var(--space-xxs)',
        'padding': 'var(--space-xxs) var(--space-sm)',
      },
    ),
    css('.import-column-chip .birka-icon').styles(
      raw: {
        'color': 'var(--color-accent)',
        'height': '14px',
        'width': '14px',
      },
    ),
    css('.import-column-chip--skipped').styles(
      raw: {
        'background': 'none',
        'border-style': 'dashed',
        'color': 'var(--color-text-subtle)',
      },
    ),
    css('.import-formats').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'repeat(auto-fit, minmax(260px, 1fr))',
      },
    ),
  ];
}
