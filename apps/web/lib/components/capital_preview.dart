import 'package:birka_web/hide_amounts_cubit.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// An example of the capital with a button that hides the amount.
///
/// It is the interactive island of the static page: only this component runs
/// in the browser.
@client
class CapitalPreview extends StatelessComponent {
  /// Creates the preview.
  const CapitalPreview({super.key});

  @override
  Component build(BuildContext context) {
    return BlocProvider(
      create: (_) => HideAmountsCubit(),
      child: BlocBuilder<HideAmountsCubit, bool>(
        builder: (context, hidden) => div(classes: 'capital', [
          div(classes: 'capital__figure', [
            const SectionLabel('Capital'),
            AmountText(
              hidden ? '•••• ₽' : '1 284 560 ₽',
              textClass: 'text-title',
            ),
          ]),
          button(
            classes: 'capital__toggle',
            attributes: {
              'aria-label': hidden ? 'Show amounts' : 'Hide amounts',
              'aria-pressed': '$hidden',
            },
            onClick: () => context.read<HideAmountsCubit>().toggle(),
            [
              svg(
                viewBox: '0 0 24 24',
                width: 20.px,
                height: 20.px,
                attributes: const {
                  'fill': 'none',
                  'stroke': 'currentColor',
                  'stroke-width': '1.8',
                  'aria-hidden': 'true',
                },
                const [
                  path(
                    d: 'M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7-10-7-10-7z',
                    [],
                  ),
                  circle(cx: '12', cy: '12', r: '3', []),
                ],
              ),
            ],
          ),
        ]),
      ),
    );
  }

  /// The styles of the preview.
  @css
  static List<StyleRule> get styles => [
    css('.capital').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
      },
    ),
    css('.capital__figure').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
      },
    ),
    css('.capital__toggle').styles(
      raw: {
        'align-items': 'center',
        'background': 'var(--color-glass-fill-top)',
        'border': '1px solid var(--color-glass-border)',
        'border-radius': 'var(--radius-pill)',
        'color': 'var(--color-text)',
        'cursor': 'pointer',
        'display': 'flex',
        'flex': 'none',
        'height': 'var(--size-touch-target)',
        'justify-content': 'center',
        'width': 'var(--size-touch-target)',
      },
    ),
  ];
}
