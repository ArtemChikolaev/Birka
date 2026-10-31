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
        AccountFormStatus.loading => const div([]),
        _ => _form(context, state),
      },
    );
  }

  Component _form(BuildContext context, AccountFormState state) {
    final cubit = context.read<AccountFormCubit>();
    final form = t.accounts.form;
    final name = state.name.trim();
    return BirkaForm(
      title: state.isNew ? form.newTitle : form.editTitle,
      closeLabel: t.app.close,
      onClose: onClose,
      submitLabel: form.save,
      onSubmit: () => unawaited(cubit.save()),
      submitting: state.status == AccountFormStatus.saving,
      failure: state.status == AccountFormStatus.failed ? form.failed : null,
      children: [
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
        BirkaChoice(
          label: form.type,
          children: [
            for (final type in state.types)
              BirkaChip(
                label: accountTypeLabel(type),
                selected: type == state.type,
                onTap: () => cubit.typeChanged(type),
              ),
          ],
        ),
        BirkaChoice(
          label: form.currency,
          children: [
            for (final currency in state.currencies)
              BirkaChip(
                label: currency.code,
                selected: currency == state.currency,
                onTap: state.isNew
                    ? () => cubit.currencyChanged(currency)
                    : null,
              ),
          ],
        ),
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
        BirkaChoice(
          label: form.art,
          children: [
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
          ],
        ),
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
      ],
    );
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.account-form__art').styles(
      raw: {
        'background': 'none',
        'border': '0',
        'border-radius': 'var(--radius-xs)',
        'cursor': 'pointer',
        'padding': '0',
      },
    ),
  ];
}
