import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:limits_common/limits_common.dart';
import 'package:limits_jaspr/src/presentation/components/limit_bits.dart';
import 'package:money/money.dart';
import 'package:rates/rates.dart';

/// The form of a monthly limit on the site (ADR 0033), a page of its own
/// with the fields in the open: the category, the sum of a month, its
/// currency when the accounts have more than one, and whether to say so
/// early. What the category spent on average, with the sum it offers, and
/// what this month took stand at the side of a wide page and under the
/// fields of a narrow one.
///
/// It needs a [LimitFormCubit] above it.
class LimitFormPage extends StatefulComponent {
  /// Creates the page.
  const LimitFormPage({
    required this.onClose,
    required this.onDone,
    super.key,
  });

  /// Leaves the form without a change.
  final VoidCallback onClose;

  /// Called once the limit is set or taken away, with what the next page
  /// says about it.
  final ValueChanged<String> onDone;

  @override
  State<LimitFormPage> createState() => _LimitFormPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.limit-form__side').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.limit-form__average').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'justify-content': 'space-between',
      },
    ),
    css('.limit-form__average-text').styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'min-width': '0'},
    ),
    css('.limit-form__average-label, .limit-form__same').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.limit-form__same').styles(raw: {'flex': 'none'}),
    css('.limit-form__month').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.limit-form__month-label').styles(
      raw: {'color': 'var(--color-text-secondary)'},
    ),
  ];
}

class _LimitFormPageState extends State<LimitFormPage> {
  /// What is typed in the sum: the cubit gets it once it reads as money.
  String? _typed;

  void _listen(LimitFormState state) {
    if (state.status == LimitFormStatus.saved ||
        state.status == LimitFormStatus.removed) {
      component.onDone(limitDone(state));
    }
  }

  @override
  Component build(BuildContext context) {
    return BlocConsumer<LimitFormCubit, LimitFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (_, state) => _listen(state),
      builder: (context, state) => switch (state.status) {
        LimitFormStatus.loading => const BirkaPlaceholder(),
        _ => _form(context, state),
      },
    );
  }

  Component _form(BuildContext context, LimitFormState state) {
    final cubit = context.read<LimitFormCubit>();
    final side = _side(context, cubit, state);
    final busy =
        state.status == LimitFormStatus.saving ||
        state.status == LimitFormStatus.saved ||
        state.status == LimitFormStatus.removed;
    return BirkaForm(
      title: limitFormTitle(state),
      closeLabel: t.app.close,
      onClose: component.onClose,
      submitLabel: t.transactions.save,
      onSubmit: () => unawaited(cubit.save()),
      ready: state.canSave,
      submitting: busy,
      failure: state.status == LimitFormStatus.failed
          ? t.limits.form.failed
          : null,
      note: limitCaption(state),
      secondary: state.editing
          ? BirkaButton(
              label: t.limits.form.remove,
              quiet: true,
              danger: true,
              onPressed: busy ? null : () => unawaited(cubit.remove()),
            )
          : null,
      aside: [
        div(classes: 'birka-wide-only', [side]),
      ],
      children: [
        if (!state.editing && state.categories.isNotEmpty)
          BirkaSelectField<String>(
            label: t.limits.form.category,
            options: {
              for (final category in state.categories)
                category.id: category.name,
            },
            selected: state.categoryId ?? state.categories.first.id,
            onChanged: (id) {
              setState(() => _typed = null);
              cubit.categoryPicked(id);
            },
          ),
        BirkaTextField(
          label: t.limits.form.perMonth,
          value: _typed ?? _shown(state.amount),
          hint: '0',
          inputMode: 'decimal',
          suffix: currencySign(state.currency),
          onChanged: (typed) {
            setState(() => _typed = typed);
            cubit.amountChanged(amountTyped(typed, state.currency));
          },
        ),
        if (state.currencies.length > 1)
          BirkaChoice(
            label: t.limits.form.currency,
            children: [
              for (final currency in state.currencies)
                BirkaChip(
                  label: t.app.currencies[currency.code] ?? currency.code,
                  selected: currency == state.currency,
                  onTap: () {
                    setState(() => _typed = null);
                    cubit.currencyPicked(currency);
                  },
                ),
            ],
          ),
        div(classes: 'birka-narrow-only', [side]),
        GlassListGroup(
          children: [
            GlassListRow(
              title: t.limits.form.warn,
              subtitle: HiddenAmounts.mask(context, limitWarnLine(state)),
              subtitleLines: 2,
              trailing: BirkaSwitch(
                value: state.warnEarly,
                label: t.limits.form.warn,
                onChanged: (on) => cubit.warnChanged(on: on),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// What the category spent on average with the sum it offers, and what
  /// this month took of a limit that is set.
  Component _side(
    BuildContext context,
    LimitFormCubit cubit,
    LimitFormState state,
  ) {
    String mask(String text) => HiddenAmounts.mask(context, text);
    final suggestion = state.suggestion;
    final spentNow = limitSpentNow(state);
    final spent = state.spent;
    final amount = state.amount;
    final parts = <Component>[
      TintedBox(
        color: 'var(--color-accent)',
        children: [
          div(classes: 'limit-form__average', [
            span(classes: 'limit-form__average-text', [
              span(classes: 'text-caption limit-form__average-label', [
                .text(t.limits.form.average),
              ]),
              span(
                classes: suggestion == null
                    ? 'text-body-strong'
                    : 'text-heading amount',
                [
                  .text(
                    suggestion == null
                        ? t.limits.form.noAverage
                        : mask(formatMoney(suggestion.average)),
                  ),
                ],
              ),
            ]),
            if (suggestion != null && state.asOffered)
              span(classes: 'text-caption limit-form__same', [
                .text(state.took ? t.limits.form.taken : t.limits.form.same),
              ])
            else if (suggestion != null)
              BirkaButton(
                label: mask(limitTake(suggestion.offer)),
                compact: true,
                onPressed: () {
                  setState(() => _typed = null);
                  cubit.takeOffer();
                },
              ),
          ]),
        ],
      ),
    ];
    if (state.editing && spentNow != null && spent != null && amount != null) {
      final share = amount.isPositive
          ? spent.minorUnits / amount.minorUnits
          : 0.0;
      parts.add(
        div(classes: 'glass limit-form__month', [
          span(classes: 'text-caption limit-form__month-label', [
            .text(mask(spentNow)),
          ]),
          BirkaMeter(
            value: share,
            label: spentNow,
            color: limitColor(_stateOf(share)),
            height: 6,
          ),
        ]),
      );
    }
    return div(classes: 'limit-form__side', parts);
  }
}

/// Where a month that took [share] of its limit stands.
LimitState _stateOf(double share) => share > 1
    ? LimitState.over
    : share >= LimitProgress.nearShare
    ? LimitState.near
    : LimitState.ok;

/// The sum of the field as the cubit holds it.
String _shown(Money? amount) =>
    amount == null || amount.isZero ? '' : typedAmount(amount);
