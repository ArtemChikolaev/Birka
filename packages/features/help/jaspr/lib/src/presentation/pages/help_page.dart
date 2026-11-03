import 'dart:async';

import 'package:design_jaspr/design_jaspr.dart';
import 'package:help_common/help_common.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// Help and feedback: the common questions with a search over them, and the
/// ways to write to the developer (ADR 0018).
///
/// A letter shows all it holds on the page, in place of the ways to write,
/// before the mail app gets it. It needs a [HelpCubit] above it.
class HelpPage extends StatefulComponent {
  /// Creates the page.
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.help__group').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.help__group .section-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.help__question').styles(raw: {'position': 'relative'}),
    // The thin line between questions, as between the rows of a list.
    css('.help__question + .help__question::before').styles(
      raw: {
        'background': 'var(--color-hairline)',
        'content': '""',
        'height': '1px',
        'left': 'var(--space-md)',
        'position': 'absolute',
        'right': 'var(--space-md)',
        'top': '0',
      },
    ),
    css('.help__ask').styles(
      raw: {
        'align-items': 'center',
        'background': 'none',
        'border': '0',
        'box-sizing': 'border-box',
        'color': 'var(--color-text)',
        'cursor': 'pointer',
        'display': 'flex',
        'font': 'inherit',
        'gap': 'var(--space-sm)',
        'min-height': 'var(--size-touch-target)',
        'padding': 'var(--space-md)',
        'text-align': 'left',
        'transition': 'background var(--duration-fast)',
        'width': '100%',
      },
    ),
    // Only where a pointer can hover: on a touch screen it would stay on.
    css.media(const MediaQuery.raw('(hover: hover)'), [
      css('.help__ask:hover').styles(
        raw: {'background': 'var(--color-glass-fill-bottom)'},
      ),
    ]),
    css('.help__asked').styles(raw: {'flex': '1', 'min-width': '0'}),
    // The chevron points down, and up once the answer shows.
    css('.help__chevron').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'display': 'flex',
        'flex': 'none',
        'transform': 'rotate(90deg)',
        'transition': 'transform var(--duration-base) var(--easing-standard)',
      },
    ),
    css('.help__chevron .birka-icon').styles(
      raw: {'height': '16px', 'width': '16px'},
    ),
    css('.help__question--open .help__chevron').styles(
      raw: {'transform': 'rotate(-90deg)'},
    ),
    // The answer opens to its height and closes again.
    css('.help__answer').styles(
      raw: {
        'display': 'grid',
        'grid-template-rows': '0fr',
        'transition':
            'grid-template-rows var(--duration-base) var(--easing-standard)',
      },
    ),
    css('.help__question--open .help__answer').styles(
      raw: {'grid-template-rows': '1fr'},
    ),
    css('.help__answer-inner').styles(
      raw: {'min-height': '0', 'overflow': 'hidden'},
    ),
    css('.help__answered').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'margin': '0',
        'padding': '0 var(--space-md) var(--space-md)',
      },
    ),
    css('.help__nothing').styles(
      raw: {
        'color': 'var(--color-text-secondary)',
        'margin': '0',
        'padding': 'var(--space-md)',
      },
    ),
    css('.help__end').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'display': 'flex',
        'flex': 'none',
      },
    ),
    css('.help__end .birka-icon').styles(
      raw: {'height': '18px', 'width': '18px'},
    ),
    css('.help__letter').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
        'padding': 'var(--space-xxs)',
      },
    ),
    css('.help__title').styles(
      raw: {'color': 'var(--color-text)', 'margin': '0'},
    ),
    css('.help__text').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css('.help__preview').styles(
      raw: {
        'background': 'var(--color-glass-fill-bottom)',
        'border': '1px solid var(--color-hairline)',
        'border-radius': 'var(--radius-md)',
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'padding': 'var(--space-md)',
      },
    ),
    css('.help__field').styles(
      raw: {
        'color': 'var(--color-text)',
        'margin': '0',
        'overflow-wrap': 'anywhere',
      },
    ),
    css('.help__name').styles(raw: {'color': 'var(--color-text-muted)'}),
    css('.help__body').styles(
      raw: {
        'border-top': '1px solid var(--color-hairline)',
        'color': 'var(--color-text)',
        'margin': 'var(--space-xs) 0 0',
        'padding-top': 'var(--space-sm)',
        'white-space': 'pre-line',
      },
    ),
    css('.help__note').styles(
      raw: {'color': 'var(--color-text-muted)', 'margin': '0'},
    ),
    css('.help__actions').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.help__about').styles(
      raw: {
        'color': 'var(--color-text-subtle)',
        'margin': '0',
        'text-align': 'center',
      },
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.help__chevron, .help__answer').styles(
        raw: {'transition': 'none'},
      ),
    ]),
  ];
}

class _HelpPageState extends State<HelpPage> {
  /// The notice on screen, if any, and how many came before it, which gives
  /// each its own message.
  HelpNotice? _notice;
  int _notices = 0;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<HelpCubit>();
    return BlocConsumer<HelpCubit, HelpState>(
      listenWhen: (previous, current) =>
          current.notice != null && current.notice != previous.notice,
      listener: (context, state) => setState(() {
        _notice = state.notice;
        _notices++;
      }),
      builder: (context, state) {
        final shown = [
          for (final (index, question) in helpQuestions().indexed)
            if (question.matches(state.query)) (index, question),
        ];
        final letter = state.letter;
        final about = state.about;
        final notice = _notice;
        return BirkaColumn(
          children: [
            GlassPageHeader(title: t.help.title),
            GlassSearchField(
              label: t.help.search,
              clearLabel: t.help.clearSearch,
              value: state.query,
              onChanged: cubit.search,
              hint: t.help.search,
            ),
            section(classes: 'help__group', [
              SectionLabel(t.help.questions),
              GlassListGroup(
                children: [
                  for (final (index, question) in shown)
                    _Question(
                      key: ValueKey(index),
                      index: index,
                      question: question,
                      open: state.open == index,
                      onTap: () => cubit.toggle(index),
                    ),
                  if (shown.isEmpty)
                    p(classes: 'text-body help__nothing', [
                      .text(t.help.nothingFound),
                    ]),
                ],
              ),
            ]),
            if (letter != null)
              _letter(cubit, letter)
            else
              section(classes: 'help__group', [
                SectionLabel(t.help.contact),
                GlassListGroup(
                  children: [
                    for (final (kind, color) in [
                      (LetterKind.question, 'var(--color-accent)'),
                      (LetterKind.bug, 'var(--color-negative)'),
                      (LetterKind.idea, 'var(--color-palette-amber)'),
                    ])
                      GlassListRow(
                        leading: DotBadge(color: color),
                        title: letterWayLabel(kind),
                        subtitle: letterWayText(kind),
                        subtitleLines: 2,
                        trailing: const span(classes: 'help__end', [
                          BirkaIcon(BirkaGlyph.chevron),
                        ]),
                        onTap: () => unawaited(cubit.compose(kind)),
                      ),
                    GlassListRow(
                      leading: const DotBadge(
                        color: 'var(--color-text-secondary)',
                      ),
                      title: t.help.github,
                      subtitle: t.help.githubText,
                      subtitleLines: 2,
                      trailing: const span(classes: 'help__end', [
                        BirkaIcon(BirkaGlyph.rise),
                      ]),
                      onTap: () => unawaited(cubit.openIssues()),
                    ),
                  ],
                ),
              ]),
            if (about != null)
              p(classes: 'text-caption help__about', [
                .text(aboutLine(about)),
              ]),
            if (notice != null)
              GlassToast(
                helpNoticeLabel(notice),
                key: ValueKey(_notices),
                trouble: true,
                onGone: () => setState(() => _notice = null),
              ),
          ],
        );
      },
    );
  }

  /// All that [letter] holds, and whether the mail app gets it.
  Component _letter(HelpCubit cubit, HelpLetter letter) {
    Component field(String name, String value) =>
        p(classes: 'text-caption help__field', [
          span(classes: 'help__name', [.text('$name: ')]),
          .text(value),
        ]);
    return GlassSurface(
      child: div(classes: 'help__letter', [
        h2(classes: 'text-heading help__title', [
          .text(letterTitle(letter.kind)),
        ]),
        p(classes: 'text-body help__text', [.text(t.help.letterText)]),
        div(classes: 'help__preview', [
          field(t.help.to, letter.address),
          field(t.help.subject, letter.subject),
          p(classes: 'text-caption help__body', [
            .text(letterBodyLabel(letter)),
          ]),
        ]),
        p(classes: 'text-caption help__note', [.text(t.help.letterPrivacy)]),
        div(classes: 'help__actions', [
          BirkaButton(
            label: t.help.openMail,
            onPressed: () => unawaited(cubit.send()),
          ),
          BirkaButton(
            label: t.help.cancel,
            quiet: true,
            onPressed: cubit.dismiss,
          ),
        ]),
      ]),
    );
  }
}

/// A common question. Its answer opens under it, and the chevron turns.
class _Question extends StatelessComponent {
  const _Question({
    required this.index,
    required this.question,
    required this.open,
    required this.onTap,
    super.key,
  });

  final int index;
  final HelpQuestion question;
  final bool open;
  final VoidCallback onTap;

  @override
  Component build(BuildContext context) {
    final answer = 'help-answer-$index';
    return div(
      classes: open ? 'help__question help__question--open' : 'help__question',
      [
        button(
          classes: 'help__ask',
          type: ButtonType.button,
          attributes: {'aria-expanded': '$open', 'aria-controls': answer},
          onClick: onTap,
          [
            span(classes: 'text-body-strong help__asked', [
              .text(question.question),
            ]),
            const span(classes: 'help__chevron', [
              BirkaIcon(BirkaGlyph.chevron),
            ]),
          ],
        ),
        // A closed answer stays in place to animate, out of reach.
        div(
          id: answer,
          classes: 'help__answer',
          attributes: open
              ? const {}
              : const {'aria-hidden': 'true', 'inert': ''},
          [
            div(classes: 'help__answer-inner', [
              p(classes: 'text-body help__answered', [.text(question.answer)]),
            ]),
          ],
        ),
      ],
    );
  }
}
