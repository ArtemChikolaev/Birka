import 'dart:async';

import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_jaspr/src/presentation/components/account_hero_card.dart';
import 'package:accounts_jaspr/src/presentation/components/card_art_of.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The form of a new or an existing account.
///
/// It needs an [AccountFormCubit] above it.
class AccountFormPage extends StatelessComponent {
  /// Creates the page. [onClose] is called when the form is done or
  /// cancelled.
  const AccountFormPage({required this.onClose, super.key});

  /// Closes the form.
  final VoidCallback onClose;

  @override
  Component build(BuildContext context) {
    return BlocConsumer<AccountFormCubit, AccountFormState>(
      // A link can lead to an account that this browser does not have.
      listenWhen: (previous, current) =>
          current.status == AccountFormStatus.saved ||
          (previous.status == AccountFormStatus.loading &&
              current.status == AccountFormStatus.failed),
      listener: (_, _) => onClose(),
      builder: (context, state) => switch (state.status) {
        AccountFormStatus.loading => const div(classes: 'account-form', []),
        _ => _form(context, state),
      },
    );
  }

  Component _form(BuildContext context, AccountFormState state) {
    final cubit = context.read<AccountFormCubit>();
    final form = t.accounts.form;
    final name = state.name.trim();
    return BirkaForm(
      classes: 'account-form',
      onSubmit: () => unawaited(cubit.save()),
      children: [
        div(classes: 'account-form__header', [
          h1(classes: 'text-heading account-form__title', [
            .text(state.isNew ? form.newTitle : form.editTitle),
          ]),
          GlassIconButton(
            glyph: BirkaGlyph.close,
            label: t.app.close,
            onPressed: onClose,
          ),
        ]),
        AccountHeroCard(
          art: cardArtOf(state.art),
          name: name.isEmpty ? form.namePlaceholder : name,
          subtitle: accountSubtitle(
            currency: state.currency,
            type: state.type,
            lastDigits: state.lastDigits,
          ),
          amount: formatMoney(state.previewBalance),
        ),
        BirkaTextField(
          label: form.name,
          value: state.name,
          hint: form.namePlaceholder,
          error: state.errors.contains(AccountFormError.nameMissing)
              ? form.nameMissing
              : null,
          onChanged: cubit.nameChanged,
          sentence: true,
        ),
        _Choice(form.type, [
          for (final type in state.types)
            BirkaChip(
              label: accountTypeLabel(type),
              selected: type == state.type,
              onTap: () => cubit.typeChanged(type),
            ),
        ]),
        _Choice(form.currency, [
          for (final currency in state.currencies)
            BirkaChip(
              label: currency.code,
              selected: currency == state.currency,
              onTap: state.isNew ? () => cubit.currencyChanged(currency) : null,
            ),
        ]),
        BirkaTextField(
          label: state.isDebt ? form.debt : form.openingBalance,
          value: state.amount,
          hint: '0',
          error: state.errors.contains(AccountFormError.amountInvalid)
              ? form.amountInvalid
              : null,
          onChanged: cubit.amountChanged,
          inputMode: 'decimal',
          textClass: 'text-amount',
        ),
        if (state.hasCard)
          BirkaTextField(
            label: form.lastDigits,
            value: state.lastDigits,
            hint: '4568',
            error: state.errors.contains(AccountFormError.lastDigitsInvalid)
                ? form.lastDigitsInvalid
                : null,
            onChanged: cubit.lastDigitsChanged,
            inputMode: 'numeric',
            maxLength: 4,
          ),
        _Choice(form.art, [
          for (final art in AccountArt.values)
            button(
              classes: 'account-form__art',
              type: ButtonType.button,
              onClick: () => cubit.artChanged(art),
              attributes: {
                'aria-label': art.name,
                'aria-pressed': '${art == state.art}',
              },
              [
                CardArtThumbnail(
                  art: cardArtOf(art),
                  highlighted: art == state.art,
                ),
              ],
            ),
        ]),
        GlassListGroup(
          children: [
            GlassListRow(
              title: form.includeInTotals,
              trailing: BirkaSwitch(
                value: state.includeInTotals,
                label: form.includeInTotals,
                onChanged: (value) =>
                    cubit.includeInTotalsChanged(value: value),
              ),
            ),
            if (!state.isNew)
              GlassListRow(
                title: state.archived ? form.restore : form.archive,
                onTap: cubit.toggleArchived,
              ),
          ],
        ),
        div(classes: 'account-form__actions', [
          if (state.status == AccountFormStatus.failed)
            p(classes: 'text-caption account-form__failed', [
              .text(form.failed),
            ]),
          BirkaButton(
            label: form.save,
            submits: state.status != AccountFormStatus.saving,
          ),
        ]),
      ],
    );
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.account-form').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-lg)',
      },
    ),
    css('.account-form__header').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'justify-content': 'space-between',
      },
    ),
    css('.account-form__title').styles(raw: {'margin': '0'}),
    css('.account-form__art').styles(
      raw: {
        'background': 'none',
        'border': '0',
        'border-radius': 'var(--radius-xs)',
        'cursor': 'pointer',
        'padding': '0',
      },
    ),
    css('.account-form__actions').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.account-form__failed').styles(
      raw: {
        'color': 'var(--color-negative)',
        'margin': '0',
        'text-align': 'center',
      },
    ),
    css('.account-form__choice').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.account-form__choice-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.account-form__options').styles(
      raw: {'display': 'flex', 'flex-wrap': 'wrap', 'gap': 'var(--space-xs)'},
    ),
  ];
}

/// A labelled row of options.
class _Choice extends StatelessComponent {
  const _Choice(this.label, this.options);

  final String label;
  final List<Component> options;

  @override
  Component build(BuildContext context) {
    return div(classes: 'account-form__choice', [
      span(classes: 'text-caption account-form__choice-label', [.text(label)]),
      div(classes: 'account-form__options', options),
    ]);
  }
}
