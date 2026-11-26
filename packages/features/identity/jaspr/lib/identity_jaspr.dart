import 'package:design_jaspr/design_jaspr.dart';
import 'package:identity_common/identity_common.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// Email-code access. Local record counts come from the host.
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
  var _email = '';
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
          prior.challenge != next.challenge || prior.step != next.step,
      listener: (_, state) {
        _code = '';
        if (state.step == AccountStep.email) _email = state.email;
      },
      builder: (context, state) {
        final issue = state.issue;
        final back = switch (state.step) {
          AccountStep.code => account.editEmail,
          AccountStep.copy => () => account.showCopy(open: false),
          _ => component.onBack,
        };
        final backLabel = switch (state.step) {
          AccountStep.code => strings.change,
          AccountStep.copy => strings.copyBack,
          _ => strings.back,
        };
        Component action(
          String label,
          VoidCallback call, {
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
        }) => form(
          classes: 'identity__stack',
          events: {
            'submit': (event) {
              event.preventDefault();
              if (!state.busy) submit();
            },
          },
          [
            field,
            BirkaButton(
              label: state.busy ? strings.working : label,
              submits: !state.busy,
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
              AccountStep.email => [
                heading(strings.entry, glyph: BirkaGlyph.contact),
                note(strings.intro),
                fieldForm(
                  field: BirkaTextField(
                    key: const ValueKey('email'),
                    label: strings.email,
                    value: _email,
                    onChanged: (v) => _email = v,
                    inputMode: 'email',
                    autocomplete: 'email',
                    maxLength: 254,
                    error: issue == AccountIssue.email
                        ? strings.badEmail
                        : null,
                  ),
                  label: strings.send,
                  submit: () => account.request(_email),
                ),
                action(strings.guest, component.onBack, quiet: true),
              ],
              AccountStep.code => [
                heading(strings.codeTitle),
                note(strings.sent(email: state.email)),
                fieldForm(
                  field: BirkaTextField(
                    key: ValueKey(state.challenge),
                    label: strings.code,
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
                  strings.resend,
                  () => account.request(state.email),
                  quiet: true,
                ),
              ],
              AccountStep.profile => [
                heading(strings.profile, glyph: BirkaGlyph.check),
                strong([.text(state.email)]),
                note(
                  component.accounts == 0 && component.operations == 0
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
                issue != AccountIssue.email &&
                issue != AccountIssue.code)
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
