import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:onboarding_common/onboarding_common.dart';

/// What a new device starts with: what Birka is, the first account and the
/// ready categories.
///
/// It needs an [OnboardingCubit] above it.
class OnboardingPage extends StatelessWidget {
  /// Creates the page. [onFinished] opens the app.
  const OnboardingPage({required this.onFinished, super.key});

  /// Called once everything is kept.
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: BlocConsumer<OnboardingCubit, OnboardingState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == OnboardingStatus.finished) onFinished();
            },
            buildWhen: (previous, current) => previous.step != current.step,
            builder: (context, state) => PopScope(
              canPop: state.step == OnboardingStep.welcome,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) context.read<OnboardingCubit>().back();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(step: state.step),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: BirkaTokens.durationBaseMs,
                      ),
                      child: switch (state.step) {
                        OnboardingStep.welcome => const _WelcomeStep(
                          key: ValueKey(OnboardingStep.welcome),
                        ),
                        OnboardingStep.account => const _AccountStep(
                          key: ValueKey(OnboardingStep.account),
                        ),
                        OnboardingStep.categories => const _CategoriesStep(
                          key: ValueKey(OnboardingStep.categories),
                        ),
                      },
                    ),
                  ),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The way back, how far the steps have come and the way out.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BirkaTokens.spaceLg,
        BirkaTokens.spaceXs,
        BirkaTokens.spaceLg,
        BirkaTokens.spaceXs,
      ),
      child: Row(
        children: [
          if (step != OnboardingStep.welcome) ...[
            GlassIconButton(
              glyph: BirkaGlyph.back,
              label: t.onboarding.back,
              onPressed: cubit.back,
            ),
            const SizedBox(width: BirkaTokens.spaceSm),
          ],
          Expanded(
            child: BirkaStepBars(
              count: OnboardingStep.values.length,
              current: step.index,
            ),
          ),
          const SizedBox(width: BirkaTokens.spaceMd),
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(cubit.skip()),
              child: SizedBox(
                height: BirkaTokens.sizeTouchTarget,
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    t.onboarding.skip,
                    style: BirkaTextStyles.of(context).bodyStrong.copyWith(
                      color: BirkaColors.of(context).textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The title and the words under it, which every step starts with.
class _Heading extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: (hero ? styles.hero : styles.title).copyWith(
            color: colors.text,
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        Text(text, style: styles.body.copyWith(color: colors.textSecondary)),
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({super.key});

  Future<void> _pickBaseCurrency(
    BuildContext context,
    Currency? selected,
  ) async {
    final cubit = context.read<OnboardingCubit>();
    final picked = await showChoiceSheet<Currency?>(
      context,
      title: t.settings.baseCurrency,
      choices: baseCurrencyChoices,
      selected: selected,
      labelOf: baseCurrencyLabel,
    );
    if (picked case (final currency,)) {
      await cubit.baseCurrencyChanged(currency);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: BirkaTokens.spaceLg),
      children: [
        const WelcomeArt(),
        const SizedBox(height: BirkaTokens.spaceSm),
        _Heading(
          title: t.onboarding.welcome.title,
          text: t.onboarding.welcome.text,
          hero: true,
        ),
        const SizedBox(height: BirkaTokens.spaceMd),
        Wrap(
          spacing: BirkaTokens.spaceXs,
          runSpacing: BirkaTokens.spaceXs,
          children: [
            for (final language in AppLocale.values)
              BirkaChip(
                label: languageLabel(language),
                selected: language == LocaleSettings.currentLocale,
                onTap: () => unawaited(cubit.languageChanged(language)),
              ),
          ],
        ),
        const SizedBox(height: BirkaTokens.spaceMd),
        BlocSelector<OnboardingCubit, OnboardingState, Currency?>(
          selector: (state) => state.baseCurrency,
          builder: (context, currency) => GlassListGroup(
            children: [
              GlassListRow(
                title: t.settings.baseCurrency,
                trailing: GlassListValue(baseCurrencyLabel(currency)),
                onTap: () => unawaited(_pickBaseCurrency(context, currency)),
              ),
            ],
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceMd),
      ],
    );
  }
}

class _AccountStep extends StatefulWidget {
  const _AccountStep({super.key});

  @override
  State<_AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends State<_AccountStep> {
  late final _name = TextEditingController(
    text: context.read<OnboardingCubit>().state.name,
  );
  late final _amount = TextEditingController(
    text: context.read<OnboardingCubit>().state.amount,
  );

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final styles = BirkaTextStyles.of(context);
    final form = t.accounts.form;
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final name = state.name.trim();
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
            horizontal: BirkaTokens.spaceLg,
            vertical: BirkaTokens.spaceXs,
          ),
          children: [
            _Heading(
              title: t.onboarding.account.title,
              text: t.onboarding.account.text,
            ),
            const SizedBox(height: BirkaTokens.spaceMd),
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
            const SizedBox(height: BirkaTokens.spaceLg),
            BirkaTextField(
              label: form.name,
              controller: _name,
              hint: form.namePlaceholder,
              error: state.errors.contains(OnboardingError.nameMissing)
                  ? form.nameMissing
                  : null,
              onChanged: cubit.nameChanged,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: BirkaTokens.spaceMd),
            BirkaTextField(
              label: form.balance,
              controller: _amount,
              hint: '0',
              error: state.errors.contains(OnboardingError.amountInvalid)
                  ? form.amountInvalid
                  : null,
              onChanged: cubit.amountChanged,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textStyle: styles.amount,
            ),
            const SizedBox(height: BirkaTokens.spaceMd),
            _Label(form.currency),
            Wrap(
              spacing: BirkaTokens.spaceXs,
              runSpacing: BirkaTokens.spaceXs,
              children: [
                for (final currency in offeredCurrencies)
                  BirkaChip(
                    label: currency.code,
                    selected: currency == state.currency,
                    onTap: () => cubit.currencyChanged(currency),
                  ),
              ],
            ),
            const SizedBox(height: BirkaTokens.spaceMd),
            _Label(form.type),
            Wrap(
              spacing: BirkaTokens.spaceXs,
              runSpacing: BirkaTokens.spaceXs,
              children: [
                for (final type in offeredFirstTypes)
                  BirkaChip(
                    label: t.accounts.types[type.name] ?? type.name,
                    selected: type == state.type,
                    onTap: () => cubit.typeChanged(type),
                  ),
              ],
            ),
            const SizedBox(height: BirkaTokens.spaceMd),
          ],
        );
      },
    );
  }
}

class _CategoriesStep extends StatelessWidget {
  const _CategoriesStep({super.key});

  static String _labelOf(CategorySet set) => switch (set) {
    CategorySet.short => t.onboarding.categories.short,
    CategorySet.full => t.onboarding.categories.full,
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final colors = BirkaColors.of(context);
    return BlocSelector<OnboardingCubit, OnboardingState, CategorySet>(
      selector: (state) => state.categorySet,
      builder: (context, selected) => ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BirkaTokens.spaceLg,
          vertical: BirkaTokens.spaceXs,
        ),
        children: [
          _Heading(
            title: t.onboarding.categories.title,
            text: t.onboarding.categories.text,
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          GlassListGroup(
            children: [
              for (final set in CategorySet.values)
                GlassListRow(
                  title: _labelOf(set),
                  subtitle: t.onboarding.categories.count(
                    n: set.categories.length,
                  ),
                  trailing: set == selected
                      ? BirkaIcon(BirkaGlyph.check, color: colors.accent)
                      : null,
                  onTap: () => cubit.categorySetChanged(set),
                ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
          Wrap(
            spacing: BirkaTokens.spaceMd,
            runSpacing: BirkaTokens.spaceSm,
            children: [
              for (final category in selected.categories)
                _CategoryTag(category),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag(this.category);

  final ReadyCategory category;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlyphBadge(
          glyph: BirkaGlyph.named(category.icon),
          color: BirkaColors.fromHex(category.color),
          size: 30,
        ),
        const SizedBox(width: BirkaTokens.spaceXs),
        Text(
          category.name,
          style: BirkaTextStyles.of(context).body.copyWith(
            color: BirkaColors.of(context).textSecondary,
          ),
        ),
      ],
    );
  }
}

/// The way forward, with what stopped it the last time.
class _Footer extends StatelessWidget {
  const _Footer();

  static String _labelOf(OnboardingStep step) => switch (step) {
    OnboardingStep.welcome => t.onboarding.welcome.start,
    OnboardingStep.account => t.onboarding.account.next,
    OnboardingStep.categories => t.onboarding.categories.finish,
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      buildWhen: (previous, current) =>
          previous.step != current.step || previous.status != current.status,
      builder: (context, state) => Padding(
        padding: const EdgeInsets.fromLTRB(
          BirkaTokens.spaceLg,
          BirkaTokens.spaceXs,
          BirkaTokens.spaceLg,
          BirkaTokens.spaceMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.status == OnboardingStatus.failed) ...[
              Text(
                t.onboarding.failed,
                textAlign: TextAlign.center,
                style: BirkaTextStyles.of(context).caption.copyWith(
                  color: BirkaColors.of(context).negative,
                ),
              ),
              const SizedBox(height: BirkaTokens.spaceXs),
            ],
            BirkaArrowButton(
              label: _labelOf(state.step),
              onPressed: state.status == OnboardingStatus.saving
                  ? null
                  : () => unawaited(cubit.next()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BirkaTokens.spaceXs),
      child: Text(
        text,
        style: BirkaTextStyles.of(
          context,
        ).caption.copyWith(color: BirkaColors.of(context).textMuted),
      ),
    );
  }
}
