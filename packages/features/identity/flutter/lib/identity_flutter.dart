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
  final _email = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
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
                prior.challenge != next.challenge || prior.step != next.step,
            listener: (_, state) {
              _code.clear();
              if (state.step == AccountStep.email) _email.text = state.email;
            },
            builder: (context, state) {
              final issue = state.issue;
              final back = switch (state.step) {
                AccountStep.code => account.editEmail,
                AccountStep.copy => () => account.showCopy(open: false),
                _ => widget.onBack,
              };
              final backLabel = switch (state.step) {
                AccountStep.code => strings.change,
                AccountStep.copy => strings.copyBack,
                _ => strings.back,
              };
              Widget action(
                String label,
                VoidCallback call, {
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
                  AccountStep.email => [
                    heading(strings.entry, glyph: BirkaGlyph.contact),
                    note(strings.intro),
                    BirkaTextField(
                      key: const ValueKey('email'),
                      label: strings.email,
                      controller: _email,
                      autofillHints: const [AutofillHints.email],
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [LengthLimitingTextInputFormatter(254)],
                      textInputAction: TextInputAction.done,
                      onSubmitted: account.request,
                      error: issue == AccountIssue.email
                          ? strings.badEmail
                          : null,
                    ),
                    action(
                      state.busy ? strings.working : strings.send,
                      () => account.request(_email.text),
                    ),
                    action(strings.guest, widget.onBack, quiet: true),
                  ],
                  AccountStep.code => [
                    heading(strings.codeTitle),
                    note(strings.sent(email: state.email)),
                    BirkaTextField(
                      key: const ValueKey('code'),
                      label: strings.code,
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
                      strings.resend,
                      () => account.request(state.email),
                      quiet: true,
                    ),
                  ],
                  AccountStep.profile => [
                    heading(strings.profile, glyph: BirkaGlyph.check),
                    Text(
                      state.email,
                      style: styles.bodyStrong.copyWith(color: colors.text),
                    ),
                    note(
                      widget.accounts == 0 && widget.operations == 0
                          ? strings.fresh
                          : strings.local,
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
                    issue != AccountIssue.email &&
                    issue != AccountIssue.code)
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
