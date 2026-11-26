import 'package:design_jaspr/design_jaspr.dart';
import 'package:identity_common/identity_common.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// Optional account access. Local record counts come from the host.
class IdentityPage extends StatefulComponent {
  /// Creates the account page.
  const IdentityPage({
    required this.onBack,
    this.accounts,
    this.operations,
    super.key,
  });

  /// Opens More.
  final VoidCallback onBack;

  /// Locally available account count.
  final int? accounts;

  /// Locally available operation count.
  final int? operations;

  @override
  State<IdentityPage> createState() => _IdentityPageState();

  /// The account card and its wide-screen navigation.
  @css
  static List<StyleRule> get styles => [
    css('.identity').styles(raw: {'display': 'grid', 'gap': 'var(--space-lg)'}),
    css('.identity__menu').styles(raw: {'display': 'none'}),
    css.media(const MediaQuery.raw(wideScreenQuery), [
      css('.identity').styles(
        raw: {
          'grid-template-columns': 'minmax(0, 260px) minmax(0, 560px)',
          'justify-content': 'center',
          'gap': 'var(--space-xxl)',
        },
      ),
      css('.identity__menu').styles(raw: {'display': 'block'}),
    ]),
    css('.identity__stack').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-md)',
        'min-width': '0',
        'overflow-wrap': 'anywhere',
      },
    ),
    css('.identity__heading').styles(
      raw: {
        'display': 'flex',
        'align-items': 'center',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.identity :is(h1,h2,p,ol)').styles(raw: {'margin': '0'}),
    css('.identity p').styles(raw: {'color': 'var(--color-text-muted)'}),
    css(
      '.identity p[role="alert"]',
    ).styles(raw: {'color': 'var(--color-negative)'}),
  ];
}

class _IdentityPageState extends State<IdentityPage> {
  var _destination = '';
  var _code = '';

  @override
  Component build(BuildContext context) {
    final account = context.read<IdentityCubit>();
    final strings = t.identity;
    final summary = localRecordSummary(
      component.accounts,
      component.operations,
    );
    Component heading(String title, {BirkaGlyph? glyph}) =>
        div(classes: 'identity__heading', [
          if (glyph != null)
            GlyphBadge(glyph: glyph, color: 'var(--color-accent)'),
          h2(classes: 'text-heading', [.text(title)]),
        ]);
    Component note(String value) => p(classes: 'text-body', [.text(value)]);
    return BlocConsumer<IdentityCubit, IdentityState>(
      listenWhen: (prior, next) =>
          prior.challenge != next.challenge ||
          prior.step != next.step ||
          prior.method != next.method,
      listener: (_, state) {
        _code = '';
        if (state.step == AccountStep.entry) _destination = state.destination;
      },
      builder: (context, state) {
        final issue = state.issue;
        final back = switch (state.step) {
          AccountStep.code ||
          AccountStep.problem => () => account.entry(state.method),
          AccountStep.registration => account.cancel,
          AccountStep.entry when state.linking => account.cancel,
          AccountStep.copy => () => account.showCopy(open: false),
          _ => component.onBack,
        };
        final backLabel = switch (state.step) {
          AccountStep.code || AccountStep.problem =>
            state.telegram ? strings.changePhone : strings.change,
          AccountStep.entry when state.linking => strings.copyBack,
          AccountStep.registration => strings.method,
          AccountStep.copy => strings.copyBack,
          _ => strings.back,
        };
        Component action(
          String label,
          VoidCallback? call, {
          bool quiet = false,
        }) => BirkaButton(
          label: label,
          onPressed: state.busy ? null : call,
          quiet: quiet,
        );
        Component fieldForm({
          required BirkaTextField field,
          required String label,
          required VoidCallback submit,
          Component? consent,
          bool enabled = true,
        }) => form(
          classes: 'identity__stack',
          events: {
            'submit': (event) {
              event.preventDefault();
              if (!state.busy && enabled) submit();
            },
          },
          [
            field,
            ?consent,
            BirkaButton(
              label: state.busy ? strings.working : label,
              submits: !state.busy && enabled,
            ),
          ],
        );
        final card = GlassSurface(
          child: div(classes: 'identity__stack', [
            ...switch (state.step) {
              AccountStep.loading => [note(strings.working)],
              AccountStep.retry || AccountStep.unconfigured => [
                if (state.step == AccountStep.unconfigured)
                  note(strings.offline),
                if (state.step == AccountStep.retry)
                  action(strings.retry, account.restore),
                action(strings.guest, component.onBack, quiet: true),
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
                fieldForm(
                  field: BirkaTextField(
                    key: ValueKey(state.method),
                    label: state.telegram ? strings.phone : strings.email,
                    value: _destination,
                    onChanged: (value) {
                      _destination = value;
                      if (state.telegram) {
                        account.allowPhone(value, allowed: false);
                      }
                    },
                    inputMode: state.telegram ? 'tel' : 'email',
                    autocomplete: state.telegram ? 'tel' : 'email',
                    maxLength: state.telegram ? 32 : 254,
                    error:
                        issue == AccountIssue.phone ||
                            issue == AccountIssue.email
                        ? accountIssueLabel(issue!)
                        : null,
                  ),
                  consent: state.telegram
                      ? div(classes: 'identity__heading', [
                          BirkaCheckbox(
                            checked: state.consent,
                            label: strings.consent,
                            onChanged: (checked) => account.allowPhone(
                              _destination,
                              allowed: checked,
                            ),
                          ),
                          note(strings.consent),
                        ])
                      : null,
                  enabled: !state.telegram || state.consent,
                  label: state.telegram ? strings.sendTelegram : strings.send,
                  submit: () => account.request(_destination),
                ),
                action(
                  state.linking ? strings.cancelLink : strings.guest,
                  state.linking ? account.cancel : component.onBack,
                  quiet: true,
                ),
              ],
              AccountStep.code => [
                heading(
                  state.telegram ? strings.telegramCode : strings.codeTitle,
                ),
                note(state.sentLabel),
                fieldForm(
                  field: BirkaTextField(
                    key: ValueKey(state.challenge),
                    label: state.telegram ? strings.birkaCode : strings.code,
                    value: _code,
                    onChanged: (v) => _code = v,
                    inputMode: 'numeric',
                    autocomplete: 'one-time-code',
                    maxLength: 6,
                    error: issue == AccountIssue.code ? strings.badCode : null,
                  ),
                  label: strings.verify,
                  submit: () => account.verify(_code),
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
                action(strings.guest, component.onBack, quiet: true),
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
                  strong([.text(value)]),
                ],
                if (state.profile?.telegram case final value?) ...[
                  note(strings.telegram),
                  strong([.text(value)]),
                ],
                note(
                  component.accounts == 0 && component.operations == 0
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
                ol(classes: 'identity__stack', [
                  for (final step in [
                    strings.copySave,
                    strings.copyMove,
                    strings.copyRestore,
                  ])
                    li([.text(step)]),
                ]),
                BirkaButton(label: t.backup.title, href: 'data/'),
                action(strings.copyBack, back, quiet: true),
              ],
            },
            if (issue != null &&
                state.step != AccountStep.problem &&
                issue != AccountIssue.phone &&
                issue != AccountIssue.email &&
                (state.step != AccountStep.code || issue != AccountIssue.code))
              p(
                attributes: const {'role': 'alert'},
                [.text(accountIssueLabel(issue))],
              ),
          ]),
        );
        return div(classes: 'identity', [
          div(classes: 'identity__menu', [
            BirkaColumn(
              children: [
                h2(classes: 'text-heading', [.text(t.app.more)]),
                GlassListGroup(
                  children: [
                    GlassListRow(
                      leading: const GlyphBadge(
                        glyph: BirkaGlyph.contact,
                        color: 'var(--color-accent)',
                      ),
                      title: strings.title,
                    ),
                  ],
                ),
              ],
            ),
          ]),
          section(classes: 'identity__stack', [
            BackHeader(label: backLabel, backLabel: backLabel, onBack: back),
            h1(classes: 'text-title', [.text(strings.title)]),
            card,
            div([
              if (summary != null) strong([.text(summary)]),
              note(strings.available),
            ]),
          ]),
        ]);
      },
    );
  }
}
