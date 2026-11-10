import 'package:design_jaspr/design_jaspr.dart';
import 'package:import_common/import_common.dart';
import 'package:import_jaspr/src/presentation/components/account_step.dart';
import 'package:import_jaspr/src/presentation/components/columns_step.dart';
import 'package:import_jaspr/src/presentation/components/copies_step.dart';
import 'package:import_jaspr/src/presentation/components/done_step.dart';
import 'package:import_jaspr/src/presentation/components/file_step.dart';
import 'package:import_jaspr/src/presentation/components/format_step.dart';
import 'package:import_jaspr/src/presentation/components/import_aside.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The import of a statement, step by step, as the boards draw it: the steps
/// as pills, the step itself, and beside it what enters the ledger with the
/// way on (ADR 0021).
///
/// On a narrow screen the side goes under the step. It needs an
/// [ImportCubit] above it.
class ImportPage extends StatefulComponent {
  /// Creates the page.
  const ImportPage({
    required this.backHref,
    required this.operationsHref,
    required this.inboxHref,
    this.onStepChanged,
    this.clock = DateTime.now,
    super.key,
  });

  /// Where the way back leads from the first and the last step.
  final String backHref;

  /// The page of the operations, after the import.
  final String operationsHref;

  /// The inbox, where what the import leaves waits.
  final String inboxHref;

  /// Called when another step comes on screen, so that the host can show it
  /// from its top: its way on stands at its end on a phone.
  final VoidCallback? onStepChanged;

  /// What the time is now, which tests can fix.
  final DateTime Function() clock;

  @override
  State<ImportPage> createState() => _ImportPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.import').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
      },
    ),
    css('.import__header').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-md)',
      },
    ),
    css('.import__heading').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': '2px',
        'min-width': '0',
      },
    ),
    css('.import__title').styles(
      raw: {'color': 'var(--color-text)', 'margin': '0'},
    ),
    css('.import__subtitle').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    // A new step fades in where the old one was.
    css('.import__step').styles(
      raw: {'animation': 'import-step var(--duration-base) var(--easing-fade)'},
    ),
    css.keyframes('import-step', {
      'from': const Styles(
        raw: {'opacity': '0', 'transform': 'translateY(6px)'},
      ),
    }),
    css('.import-stack').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
      },
    ),
    css('.import-section').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.import-section .section-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.import-section__head').styles(
      raw: {
        'align-items': 'baseline',
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-xxs) var(--space-md)',
        'justify-content': 'space-between',
      },
    ),
    css('.import-section__note').styles(
      raw: {'color': 'var(--color-text-subtle)'},
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.import__step').styles(raw: {'animation': 'none'}),
    ]),
  ];
}

class _ImportPageState extends State<ImportPage> {
  /// The past import just taken out, if any, and how many came before it,
  /// which gives each its own message.
  String? _undone;
  int _undones = 0;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<ImportCubit>();
    return BlocConsumer<ImportCubit, ImportState>(
      listenWhen: (previous, current) => previous.step != current.step,
      listener: (context, state) => component.onStepChanged?.call(),
      builder: (context, state) {
        final step = state.step;
        final undone = _undone;
        final leaves = step == ImportStep.file || state.importId != null;
        return div(classes: 'import', [
          div(classes: 'import__header', [
            GlassIconButton(
              glyph: BirkaGlyph.back,
              label: t.imports.back,
              href: leaves ? component.backHref : null,
              onPressed: leaves || state.writing ? null : cubit.back,
            ),
            div(classes: 'import__heading', [
              h1(classes: 'text-title import__title', [.text(t.imports.title)]),
              p(classes: 'text-caption import__subtitle', [
                .text(
                  t.imports.stepOf(
                    n: step.index + 1,
                    count: ImportStep.values.length,
                    what: t.imports.stepWhat[step.name] ?? '',
                  ),
                ),
              ]),
            ]),
          ]),
          GlassStepPills(
            label: t.imports.stepsLabel,
            labels: [
              for (final step in ImportStep.values)
                t.imports.steps[step.name] ?? step.name,
            ],
            current: step.index,
            reachable: state.reachable.index,
            onStep: (index) => cubit.goTo(ImportStep.values[index]),
          ),
          if (state.failed) GlassNotice(text: t.imports.failed),
          BirkaSplit(
            main: [
              div(key: ValueKey(step), classes: 'import__step', [
                switch (step) {
                  ImportStep.file => FileStep(
                    state: state,
                    now: component.clock(),
                    onUndone: (name) => setState(() {
                      _undone = name;
                      _undones++;
                    }),
                  ),
                  ImportStep.format => FormatStep(state: state),
                  ImportStep.columns => ColumnsStep(state: state),
                  ImportStep.account => AccountStep(state: state),
                  ImportStep.copies => CopiesStep(state: state),
                  ImportStep.done => DoneStep(
                    state: state,
                    inboxHref: component.inboxHref,
                  ),
                },
              ]),
            ],
            aside: [
              ImportAside(
                state: state,
                operationsHref: component.operationsHref,
                inboxHref: component.inboxHref,
              ),
            ],
          ),
          if (undone != null)
            GlassToast(
              t.imports.undone(name: undone),
              key: ValueKey(_undones),
              onGone: () => setState(() => _undone = null),
            ),
        ]);
      },
    );
  }
}
