import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:identity_common/identity_common.dart';
import 'package:l10n/l10n.dart';

/// Optional account access and instructions for moving the local ledger.
class IdentityPage extends StatefulWidget {
  /// Opens with a host-owned account cubit and local record counts.
  const IdentityPage({
    required this.onBack,
    required this.onData,
    this.accounts,
    this.operations,
    super.key,
  });

  /// Returns to More.
  final VoidCallback onBack;

  /// Opens the device's backup page.
  final VoidCallback onData;

  /// Locally available account count.
  final int? accounts;

  /// Locally available operation count.
  final int? operations;

  @override
  State<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<IdentityPage> {
  final _destination = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _destination.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = context.read<IdentityCubit>();
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final strings = t.identity;
    final summary = localRecordSummary(widget.accounts, widget.operations);
    Widget heading(String title, {BirkaGlyph? glyph}) => Row(
      children: [
        if (glyph != null) ...[
          GlyphBadge(glyph: glyph, color: colors.accent),
          const SizedBox(width: BirkaTokens.spaceSm),
        ],
        Expanded(
          child: Text(
            title,
            style: styles.heading.copyWith(color: colors.text),
          ),
        ),
      ],
    );
    Widget note(String value) =>
        Text(value, style: styles.body.copyWith(color: colors.textMuted));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: BlocConsumer<IdentityCubit, IdentityState>(
            listenWhen: (prior, next) =>
                prior.challenge != next.challenge ||
                prior.step != next.step ||
                prior.method != next.method,
            listener: (_, state) {
              _code.clear();
              if (state.step == AccountStep.entry) {
                _destination.text = state.destination;
              }
            },
            builder: (context, state) {
              final issue = state.issue;
              final back = switch (state.step) {
                AccountStep.code ||
                AccountStep.problem => () => account.entry(state.method),
                AccountStep.registration => account.cancel,
                AccountStep.entry when state.linking => account.cancel,
                AccountStep.copy => () => account.showCopy(open: false),
                _ => widget.onBack,
              };
              final backLabel = switch (state.step) {
                AccountStep.code || AccountStep.problem =>
                  state.telegram ? strings.changePhone : strings.change,
                AccountStep.entry when state.linking => strings.copyBack,
                AccountStep.registration => strings.method,
                AccountStep.copy => strings.copyBack,
                _ => strings.back,
              };
              Widget action(
                String label,
                VoidCallback? call, {
                bool quiet = false,
              }) => BirkaButton(
                label: label,
                quiet: quiet,
                onPressed: state.busy ? null : call,
              );
              final children = <Widget>[
                ...switch (state.step) {
                  AccountStep.loading => [note(strings.working)],
                  AccountStep.retry || AccountStep.unconfigured => [
                    if (state.step == AccountStep.unconfigured)
                      note(strings.offline),
                    if (state.step == AccountStep.retry)
                      action(strings.retry, account.restore),
                    action(strings.guest, widget.onBack, quiet: true),
                  ],
                  AccountStep.entry => [
                    heading(state.entryHeading, glyph: BirkaGlyph.contact),
                    if (!state.linking && state.methods.length > 1)
                      GlassSegmented(
                        segments: {
                          SignInMethod.email: strings.mailMethod,
                          SignInMethod.telegram: strings.telegram,
                        },
                        selected: state.method,
                        onChanged: account.entry,
                      ),
                    note(
                      state.linking
                          ? strings.linkIntro
                          : state.telegram
                          ? strings.telegramIntro
                          : strings.intro,
                    ),
                    BirkaTextField(
                      key: ValueKey(state.method),
                      label: state.telegram ? strings.phone : strings.email,
                      controller: _destination,
                      autofillHints: [
                        if (state.telegram)
                          AutofillHints.telephoneNumber
                        else
                          AutofillHints.email,
                      ],
                      keyboardType: state.telegram
                          ? TextInputType.phone
                          : TextInputType.emailAddress,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          state.telegram ? 32 : 254,
                        ),
                      ],
                      textInputAction: TextInputAction.done,
                      onSubmitted: account.request,
                      onChanged: (value) {
                        if (state.telegram) {
                          account.allowPhone(value, allowed: false);
                        }
                      },
                      error:
                          issue == AccountIssue.phone ||
                              issue == AccountIssue.email
                          ? accountIssueLabel(issue!)
                          : null,
                    ),
                    if (state.telegram)
                      Row(
                        children: [
                          BirkaCheckbox(
                            checked: state.consent,
                            label: strings.consent,
                            onChanged: (checked) => account.allowPhone(
                              _destination.text,
                              allowed: checked,
                            ),
                          ),
                          Expanded(child: note(strings.consent)),
                        ],
                      ),
                    action(
                      state.busy
                          ? strings.working
                          : state.telegram
                          ? strings.sendTelegram
                          : strings.send,
                      state.busy || (state.telegram && !state.consent)
                          ? null
                          : () => account.request(_destination.text),
                    ),
                    action(
                      state.linking ? strings.cancelLink : strings.guest,
                      state.linking ? account.cancel : widget.onBack,
                      quiet: true,
                    ),
                  ],
                  AccountStep.code => [
                    heading(
                      state.telegram ? strings.telegramCode : strings.codeTitle,
                    ),
                    note(state.sentLabel),
                    BirkaTextField(
                      key: const ValueKey('code'),
                      label: state.telegram ? strings.birkaCode : strings.code,
                      controller: _code,
                      autofocus: true,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onSubmitted: account.verify,
                      error: issue == AccountIssue.code
                          ? strings.badCode
                          : null,
                    ),
                    action(
                      state.busy ? strings.working : strings.verify,
                      () => account.verify(_code.text),
                    ),
                    action(
                      state.remaining > 0
                          ? strings.resendAfter(seconds: state.remaining)
                          : strings.resend,
                      state.remaining > 0
                          ? null
                          : () => account.request(state.destination),
                      quiet: true,
                    ),
                    if (state.linking)
                      action(strings.cancelLink, account.cancel, quiet: true)
                    else if (state.methods.contains(state.other))
                      action(
                        state.telegram ? strings.useEmail : strings.useTelegram,
                        () => account.entry(state.other),
                        quiet: true,
                      ),
                  ],
                  AccountStep.registration => [
                    heading(strings.confirmed, glyph: BirkaGlyph.check),
                    note(strings.newPhone),
                    if (state.methods.contains(SignInMethod.email))
                      note(strings.existingEmailHint),
                    action(strings.create, account.register),
                    if (state.methods.contains(SignInMethod.email))
                      action(
                        strings.useEmail,
                        () => account.entry(SignInMethod.email),
                        quiet: true,
                      ),
                    action(strings.guest, widget.onBack, quiet: true),
                  ],
                  AccountStep.problem => [
                    heading(accountIssueLabel(issue!)),
                    if (state.linking)
                      action(strings.copyBack, account.cancel)
                    else if (state.methods.contains(state.other))
                      action(
                        state.telegram ? strings.useEmail : strings.useTelegram,
                        () => account.entry(state.other),
                      ),
                    action(
                      state.telegram ? strings.changePhone : strings.change,
                      () => account.entry(state.method),
                      quiet: true,
                    ),
                  ],
                  AccountStep.profile => [
                    heading(strings.profile, glyph: BirkaGlyph.check),
                    if (state.profile?.email case final value?) ...[
                      note(strings.mailMethod),
                      Text(
                        value,
                        style: styles.bodyStrong.copyWith(color: colors.text),
                      ),
                    ],
                    if (state.profile?.telegram case final value?) ...[
                      note(strings.telegram),
                      Text(
                        value,
                        style: styles.bodyStrong.copyWith(color: colors.text),
                      ),
                    ],
                    note(
                      widget.accounts == 0 && widget.operations == 0
                          ? strings.fresh
                          : strings.local,
                    ),
                    if (state.canLink case final method?)
                      action(
                        method == SignInMethod.telegram
                            ? strings.linkTelegram
                            : strings.linkEmail,
                        () => account.entry(method),
                      ),
                    action(
                      strings.copy,
                      () => account.showCopy(open: true),
                      quiet: true,
                    ),
                    action(strings.logout, account.logout, quiet: true),
                  ],
                  AccountStep.copy => [
                    heading(strings.copyTitle),
                    note('1. ${strings.copySave}'),
                    note('2. ${strings.copyMove}'),
                    note('3. ${strings.copyRestore}'),
                    action(t.backup.title, widget.onData),
                    action(strings.copyBack, back, quiet: true),
                  ],
                },
                if (issue != null &&
                    state.step != AccountStep.problem &&
                    issue != AccountIssue.phone &&
                    issue != AccountIssue.email &&
                    (state.step != AccountStep.code ||
                        issue != AccountIssue.code))
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      accountIssueLabel(issue),
                      style: styles.body.copyWith(color: colors.negative),
                    ),
                  ),
              ];
              return ListView(
                padding: const EdgeInsets.all(BirkaTokens.spaceMd),
                children: [
                  BackHeader(
                    label: backLabel,
                    backLabel: backLabel,
                    onBack: back,
                  ),
                  const SizedBox(height: BirkaTokens.spaceLg),
                  Text(
                    strings.title,
                    style: styles.title.copyWith(color: colors.text),
                  ),
                  const SizedBox(height: BirkaTokens.spaceMd),
                  GlassSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: BirkaTokens.spaceMd,
                      children: children,
                    ),
                  ),
                  const SizedBox(height: BirkaTokens.spaceMd),
                  if (summary != null)
                    Text(
                      summary,
                      style: styles.bodyStrong.copyWith(color: colors.text),
                    ),
                  note(strings.available),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
