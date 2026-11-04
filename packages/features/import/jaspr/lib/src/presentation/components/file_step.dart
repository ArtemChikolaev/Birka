import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:import_common/import_common.dart';
import 'package:import_jaspr/src/presentation/components/import_bits.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';

/// The first step: the file dropped or chosen, where to get one, and the
/// past imports with their undo.
class FileStep extends StatefulComponent {
  /// Creates the step of [state].
  const FileStep({
    required this.state,
    required this.now,
    required this.onUndone,
    super.key,
  });

  /// The import.
  final ImportState state;

  /// What the time is now.
  final DateTime now;

  /// Called with the name of a past import once it is taken out.
  final ValueChanged<String> onUndone;

  @override
  State<FileStep> createState() => _FileStepState();

  /// The styles of the step.
  @css
  static List<StyleRule> get styles => [
    css('.import-where').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'repeat(auto-fit, minmax(200px, 1fr))',
      },
    ),
    css('.import-where__card').styles(
      raw: {
        'align-items': 'flex-start',
        'display': 'flex',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.import-where__text').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
      },
    ),
    css('.import-where__title').styles(raw: {'color': 'var(--color-text)'}),
    css('.import-where__line').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
    css('.import-past__actions').styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xs)',
        'justify-content': 'flex-end',
      },
    ),
  ];
}

class _FileStepState extends State<FileStep> {
  /// The past import whose undo waits for a yes.
  String? _asking;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<ImportCubit>();
    final state = component.state;
    final unreadable = state.unreadable;
    return div(classes: 'import-stack', [
      GlassSurface(
        child: FileDropZone(
          title: t.imports.dropTitle,
          text: t.imports.dropText,
          buttonLabel: t.imports.choose,
          kinds: t.imports.kinds,
          note: state.reading ? t.imports.reading : t.imports.dropNote,
          busy: state.reading,
          onChoose: () => unawaited(cubit.choose()),
          onDrop: (name, bytes) => unawaited(cubit.read(name, bytes)),
        ),
      ),
      if (unreadable != null)
        GlassNotice(
          key: ValueKey(unreadable),
          title: t.imports.unreadableTitle,
          text: t.imports.unreadable[unreadable.name] ?? t.imports.failed,
        ),
      section(classes: 'import-section', [
        SectionLabel(t.imports.whereTitle),
        div(classes: 'import-where', [
          _where(
            BirkaGlyph.wallet,
            'var(--color-palette-sky)',
            t.imports.whereBank,
            t.imports.whereBankText,
          ),
          _where(
            BirkaGlyph.copy,
            'var(--color-palette-amber)',
            t.imports.whereZen,
            t.imports.whereZenText,
          ),
          _where(
            BirkaGlyph.transfer,
            'var(--color-palette-violet)',
            t.imports.whereAbroad,
            t.imports.whereAbroadText,
          ),
        ]),
      ]),
      if (state.history.isNotEmpty)
        section(classes: 'import-section', [
          SectionLabel(t.imports.pastTitle),
          GlassListGroup(
            children: [
              for (final past in state.history) _past(cubit, state, past),
            ],
          ),
        ]),
    ]);
  }

  Component _where(BirkaGlyph glyph, String color, String title, String text) {
    return GlassSurface(
      child: div(classes: 'import-where__card', [
        GlyphBadge(glyph: glyph, color: color),
        div(classes: 'import-where__text', [
          span(classes: 'text-body-strong import-where__title', [.text(title)]),
          span(classes: 'text-caption import-where__line', [.text(text)]),
        ]),
      ]),
    );
  }

  Component _past(ImportCubit cubit, ImportState state, LedgerImport past) {
    final asking = _asking == past.id;
    final label = importLabel(past);
    return GlassListRow(
      key: ValueKey(past.id),
      leading: GlyphBadge(
        glyph: BirkaGlyph.file,
        color: FormatMark.colorOf(
          statementFormats.where((it) => it.id == past.format).firstOrNull,
        ),
      ),
      title: label,
      subtitle: asking
          ? t.imports.undoAsk(
              n: past.transactions,
              count: formatCount(past.transactions),
            )
          : importLine(past, state.accounts, now: component.now),
      subtitleLines: 2,
      trailing: div(classes: 'import-past__actions', [
        if (asking) ...[
          BirkaButton(
            label: t.imports.undoNo,
            quiet: true,
            compact: true,
            onPressed: () => setState(() => _asking = null),
          ),
          BirkaButton(
            label: t.imports.undoYes,
            danger: true,
            compact: true,
            onPressed: state.writing
                ? null
                : () async {
                    setState(() => _asking = null);
                    await cubit.undoPast(past.id);
                    component.onUndone(label);
                  },
          ),
        ] else
          BirkaButton(
            label: t.imports.undo,
            quiet: true,
            compact: true,
            onPressed: () => setState(() => _asking = past.id),
          ),
      ]),
    );
  }
}
