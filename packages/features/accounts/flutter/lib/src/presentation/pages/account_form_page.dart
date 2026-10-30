import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_flutter/src/presentation/widgets/account_hero_card.dart';
import 'package:accounts_flutter/src/presentation/widgets/account_labels.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

/// The form of a new or an existing account.
///
/// It needs an [AccountFormCubit] above it.
class AccountFormPage extends StatelessWidget {
  /// Creates the page. [onClose] is called when the form is done or
  /// cancelled.
  const AccountFormPage({required this.onClose, super.key});

  /// Closes the form.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: BlocConsumer<AccountFormCubit, AccountFormState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == AccountFormStatus.saved) onClose();
            },
            buildWhen: (previous, current) =>
                previous.status == AccountFormStatus.loading,
            builder: (context, state) => switch (state.status) {
              AccountFormStatus.loading => const SizedBox.shrink(),
              _ => _Form(initial: state, onClose: onClose),
            },
          ),
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.initial, required this.onClose});

  final AccountFormState initial;
  final VoidCallback onClose;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final _name = TextEditingController(text: widget.initial.name);
  late final _amount = TextEditingController(text: widget.initial.amount);
  late final _lastDigits = TextEditingController(
    text: widget.initial.lastDigits,
  );

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _lastDigits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AccountFormCubit>();
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return BlocBuilder<AccountFormCubit, AccountFormState>(
      builder: (context, state) {
        final form = t.accounts.form;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BirkaTokens.spaceLg,
                BirkaTokens.spaceXs,
                BirkaTokens.spaceLg,
                BirkaTokens.spaceSm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.isNew ? form.newTitle : form.editTitle,
                      style: styles.heading.copyWith(color: colors.text),
                    ),
                  ),
                  GlassIconButton(
                    glyph: BirkaGlyph.close,
                    label: t.app.close,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: BirkaTokens.spaceLg,
                  vertical: BirkaTokens.spaceXs,
                ),
                children: [
                  AccountHeroCard(
                    art: cardArtOf(state.art),
                    name: state.name.trim().isEmpty
                        ? form.namePlaceholder
                        : state.name.trim(),
                    subtitle: accountSubtitle(
                      currency: state.currency,
                      type: state.type,
                      lastDigits: state.lastDigits,
                    ),
                    amount: formatMoney(state.previewBalance),
                  ),
                  const SizedBox(height: BirkaTokens.spaceLg),
                  BirkaTextField(
                    label: form.name,
                    controller: _name,
                    hint: form.namePlaceholder,
                    error: state.errors.contains(AccountFormError.nameMissing)
                        ? form.nameMissing
                        : null,
                    onChanged: cubit.nameChanged,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: BirkaTokens.spaceMd),
                  _Label(form.type),
                  Wrap(
                    spacing: BirkaTokens.spaceXs,
                    runSpacing: BirkaTokens.spaceXs,
                    children: [
                      for (final type in state.types)
                        BirkaChip(
                          label: accountTypeLabel(type),
                          selected: type == state.type,
                          onTap: () => cubit.typeChanged(type),
                        ),
                    ],
                  ),
                  const SizedBox(height: BirkaTokens.spaceMd),
                  _Label(form.currency),
                  Wrap(
                    spacing: BirkaTokens.spaceXs,
                    runSpacing: BirkaTokens.spaceXs,
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
                  const SizedBox(height: BirkaTokens.spaceMd),
                  BirkaTextField(
                    label: state.isDebt ? form.debt : form.openingBalance,
                    controller: _amount,
                    hint: '0',
                    error: state.errors.contains(AccountFormError.amountInvalid)
                        ? form.amountInvalid
                        : null,
                    onChanged: cubit.amountChanged,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textStyle: styles.amount,
                  ),
                  if (state.hasCard) ...[
                    const SizedBox(height: BirkaTokens.spaceMd),
                    BirkaTextField(
                      label: form.lastDigits,
                      controller: _lastDigits,
                      hint: '4568',
                      error:
                          state.errors.contains(
                            AccountFormError.lastDigitsInvalid,
                          )
                          ? form.lastDigitsInvalid
                          : null,
                      onChanged: cubit.lastDigitsChanged,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                  ],
                  const SizedBox(height: BirkaTokens.spaceMd),
                  _Label(form.art),
                  Wrap(
                    spacing: BirkaTokens.spaceSm,
                    runSpacing: BirkaTokens.spaceSm,
                    children: [
                      for (final art in AccountArt.values)
                        Semantics(
                          button: true,
                          selected: art == state.art,
                          label: art.name,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => cubit.artChanged(art),
                            child: CardArtThumbnail(
                              art: cardArtOf(art),
                              highlighted: art == state.art,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: BirkaTokens.spaceLg),
                  GlassListGroup(
                    children: [
                      GlassListRow(
                        title: form.includeInTotals,
                        trailing: Switch(
                          value: state.includeInTotals,
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
                  const SizedBox(height: BirkaTokens.spaceMd),
                ],
              ),
            ),
            Padding(
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
                  if (state.status == AccountFormStatus.failed) ...[
                    Text(
                      form.failed,
                      textAlign: TextAlign.center,
                      style: styles.caption.copyWith(color: colors.negative),
                    ),
                    const SizedBox(height: BirkaTokens.spaceXs),
                  ],
                  BirkaButton(
                    label: form.save,
                    onPressed: state.status == AccountFormStatus.saving
                        ? null
                        : cubit.save,
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
