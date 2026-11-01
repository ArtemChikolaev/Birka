import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:onboarding_common/onboarding_common.dart';

/// What a new browser starts with: what Birka is, the first account and the
/// ready categories.
///
/// It needs an [OnboardingCubit] above it. It is one form, so that the Enter
/// key in a field goes to the next step.
class OnboardingPage extends StatelessComponent {
  /// Creates the page. [onFinished] opens the app.
  const OnboardingPage({required this.onFinished, super.key});

  /// Called once everything is kept.
  final VoidCallback onFinished;

  static String _forwardLabel(OnboardingStep step) => switch (step) {
    OnboardingStep.welcome => t.onboarding.welcome.start,
    OnboardingStep.account => t.onboarding.account.next,
    OnboardingStep.categories => t.onboarding.categories.finish,
  };

  @override
  Component build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (_, state) {
        if (state.status == OnboardingStatus.finished) onFinished();
      },
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();
        return form(
          classes: 'onboarding',
          events: {
            'submit': (event) {
              event.preventDefault();
              unawaited(cubit.next());
            },
          },
          [
            _TopBar(step: state.step),
            div(classes: 'onboarding__step', [
              switch (state.step) {
                OnboardingStep.welcome => const _WelcomeStep(),
                OnboardingStep.account => const _AccountStep(),
                OnboardingStep.categories => const _CategoriesStep(),
              },
            ]),
            div(classes: 'onboarding__footer', [
              if (state.status == OnboardingStatus.failed)
                p(classes: 'text-caption onboarding__failure', [
                  .text(t.onboarding.failed),
                ]),
              BirkaArrowButton(
                label: _forwardLabel(state.step),
                submits: state.status != OnboardingStatus.saving,
              ),
            ]),
          ],
        );
      },
    );
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.onboarding').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
        'min-height': 'calc(100dvh - var(--space-md) - var(--space-xxl))',
      },
    ),
    css('.onboarding__top').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'min-height': 'var(--size-touch-target)',
      },
    ),
    css('.onboarding__skip').styles(
      raw: {
        'background': 'none',
        'border': '0',
        'color': 'var(--color-text-muted)',
        'cursor': 'pointer',
        'flex': 'none',
        'height': 'var(--size-touch-target)',
        'padding': '0 0 0 var(--space-xxs)',
      },
    ),
    css('.onboarding__step').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
      },
    ),
    css('.onboarding__heading').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.onboarding__title').styles(
      raw: {'margin': '0', 'white-space': 'pre-line'},
    ),
    css('.onboarding__text').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css('.onboarding__languages').styles(
      raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': 'var(--space-xs)'},
    ),
    css('.onboarding__value').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-muted)',
        'display': 'flex',
        'flex': 'none',
        'gap': 'var(--space-xxs)',
      },
    ),
    css('.onboarding__value .birka-icon').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'height': '18px',
        'width': '18px',
      },
    ),
    css('.onboarding__check').styles(raw: {'color': 'var(--color-accent)'}),
    css('.onboarding__tags').styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': 'var(--space-sm) var(--space-md)',
      },
    ),
    css('.onboarding__tag').styles(
      raw: {
        'align-items': 'center',
        'color': 'var(--color-text-secondary)',
        'display': 'flex',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.onboarding__footer').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.onboarding__failure').styles(
      raw: {
        'color': 'var(--color-negative)',
        'margin': '0',
        'text-align': 'center',
      },
    ),
  ];
}

/// The way back, how far the steps have come and the way out.
class _TopBar extends StatelessComponent {
  const _TopBar({required this.step});

  final OnboardingStep step;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return div(classes: 'onboarding__top', [
      if (step != OnboardingStep.welcome)
        GlassIconButton(
          glyph: BirkaGlyph.back,
          label: t.onboarding.back,
          onPressed: cubit.back,
        ),
      BirkaStepBars(
        count: OnboardingStep.values.length,
        current: step.index,
      ),
      button(
        classes: 'text-body-strong onboarding__skip',
        type: ButtonType.button,
        onClick: () => unawaited(cubit.skip()),
        [.text(t.onboarding.skip)],
      ),
    ]);
  }
}

/// The title and the words under it, which every step starts with.
class _Heading extends StatelessComponent {
  const _Heading({
    required this.title,
    required this.text,
    this.hero = false,
  });

  final String title;
  final String text;

  /// Whether this is the headline of the first screen.
  final bool hero;

  @override
  Component build(BuildContext context) {
    return div(classes: 'onboarding__heading', [
      h1(
        classes: '${hero ? 'text-hero' : 'text-title'} onboarding__title',
        [.text(title)],
      ),
      p(classes: 'text-body onboarding__text', [.text(text)]),
    ]);
  }
}

class _WelcomeStep extends StatefulComponent {
  const _WelcomeStep();

  @override
  State<_WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<_WelcomeStep> {
  /// Whether the base currencies stand open under their row.
  var _picking = false;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocSelector<OnboardingCubit, OnboardingState, Currency?>(
      selector: (state) => state.baseCurrency,
      builder: (context, selected) => BirkaColumn(
        children: [
          const WelcomeArt(),
          _Heading(
            title: t.onboarding.welcome.title,
            text: t.onboarding.welcome.text,
            hero: true,
          ),
          div(classes: 'onboarding__languages', [
            for (final language in AppLocale.values)
              BirkaChip(
                label: languageLabel(language),
                selected: language == LocaleSettings.currentLocale,
                onTap: () => unawaited(cubit.languageChanged(language)),
              ),
          ]),
          GlassListGroup(
            children: [
              GlassListRow(
                title: t.settings.baseCurrency,
                trailing: span(classes: 'text-body onboarding__value', [
                  .text(baseCurrencyLabel(selected)),
                  const BirkaIcon(BirkaGlyph.chevron),
                ]),
                onTap: () => setState(() => _picking = !_picking),
              ),
              if (_picking)
                for (final currency in baseCurrencyChoices)
                  GlassListRow(
                    title: baseCurrencyLabel(currency),
                    indented: true,
                    trailing: currency == selected
                        ? const span(classes: 'onboarding__check', [
                            BirkaIcon(BirkaGlyph.check),
                          ])
                        : null,
                    onTap: () {
                      setState(() => _picking = false);
                      unawaited(cubit.baseCurrencyChanged(currency));
                    },
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountStep extends StatelessComponent {
  const _AccountStep();

  @override
  Component build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final form = t.accounts.form;
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final name = state.name.trim();
        return BirkaColumn(
          children: [
            _Heading(
              title: t.onboarding.account.title,
              text: t.onboarding.account.text,
            ),
            AccountCard(
              art: CardArt.emerald,
              name: name.isEmpty ? form.namePlaceholder : name,
              subtitle: accountLine(
                currency: state.currency.code,
                type: state.type.name,
              ),
              amount: formatMoney(state.previewBalance),
              compact: true,
            ),
            BirkaTextField(
              label: form.name,
              value: state.name,
              hint: form.namePlaceholder,
              error: state.errors.contains(OnboardingError.nameMissing)
                  ? form.nameMissing
                  : null,
              onChanged: cubit.nameChanged,
              sentence: true,
            ),
            BirkaTextField(
              label: form.balance,
              value: state.amount,
              hint: '0',
              error: state.errors.contains(OnboardingError.amountInvalid)
                  ? form.amountInvalid
                  : null,
              onChanged: cubit.amountChanged,
              inputMode: 'decimal',
              textClass: 'text-amount',
            ),
            BirkaChoice(
              label: form.currency,
              children: [
                for (final currency in offeredCurrencies)
                  BirkaChip(
                    label: currency.code,
                    selected: currency == state.currency,
                    onTap: () => cubit.currencyChanged(currency),
                  ),
              ],
            ),
            BirkaChoice(
              label: form.type,
              children: [
                for (final type in offeredFirstTypes)
                  BirkaChip(
                    label: t.accounts.types[type.name] ?? type.name,
                    selected: type == state.type,
                    onTap: () => cubit.typeChanged(type),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _CategoriesStep extends StatelessComponent {
  const _CategoriesStep();

  static String _labelOf(CategorySet set) => switch (set) {
    CategorySet.short => t.onboarding.categories.short,
    CategorySet.full => t.onboarding.categories.full,
  };

  @override
  Component build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocSelector<OnboardingCubit, OnboardingState, CategorySet>(
      selector: (state) => state.categorySet,
      builder: (context, selected) => BirkaColumn(
        children: [
          _Heading(
            title: t.onboarding.categories.title,
            text: t.onboarding.categories.text,
          ),
          GlassListGroup(
            children: [
              for (final set in CategorySet.values)
                GlassListRow(
                  title: _labelOf(set),
                  subtitle: t.onboarding.categories.count(
                    n: set.categories.length,
                  ),
                  trailing: set == selected
                      ? const span(classes: 'onboarding__check', [
                          BirkaIcon(BirkaGlyph.check),
                        ])
                      : null,
                  onTap: () => cubit.categorySetChanged(set),
                ),
            ],
          ),
          div(classes: 'onboarding__tags', [
            for (final category in selected.categories)
              span(classes: 'text-body onboarding__tag', [
                GlyphBadge(
                  glyph: BirkaGlyph.named(category.icon),
                  color: category.color,
                  size: 30,
                ),
                .text(category.name),
              ]),
          ]),
        ],
      ),
    );
  }
}
