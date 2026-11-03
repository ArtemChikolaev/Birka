import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:help_common/help_common.dart';
import 'package:l10n/l10n.dart';

/// Help and feedback: the common questions with a search over them, and the
/// ways to write to the developer (ADR 0018).
///
/// A letter opens in a sheet that shows all it holds, before the mail app
/// gets it. It needs a [HelpCubit] above it.
class HelpPage extends StatefulWidget {
  /// Creates the page.
  const HelpPage({required this.onBack, super.key});

  /// Called by the button that goes back.
  final VoidCallback onBack;

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final cubit = context.read<HelpCubit>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: MultiBlocListener(
            listeners: [
              BlocListener<HelpCubit, HelpState>(
                listenWhen: (previous, current) =>
                    current.notice != null && current.notice != previous.notice,
                listener: (context, state) => showGlassToast(
                  context,
                  helpNoticeLabel(state.notice!),
                  trouble: true,
                ),
              ),
              BlocListener<HelpCubit, HelpState>(
                listenWhen: (previous, current) =>
                    current.letter != null && current.letter != previous.letter,
                listener: (context, state) =>
                    unawaited(_offer(context, state.letter!)),
              ),
            ],
            child: BlocBuilder<HelpCubit, HelpState>(
              builder: (context, state) {
                final shown = [
                  for (final (index, question) in helpQuestions().indexed)
                    if (question.matches(state.query)) (index, question),
                ];
                final about = state.about;
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    BirkaTokens.spaceLg,
                    BirkaTokens.spaceXs,
                    BirkaTokens.spaceLg,
                    BirkaTokens.spaceXxl +
                        MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  children: [
                    BackHeader(
                      label: t.help.title,
                      backLabel: t.help.back,
                      onBack: widget.onBack,
                    ),
                    const SizedBox(height: BirkaTokens.spaceLg),
                    GlassSearchField(
                      label: t.help.search,
                      clearLabel: t.help.clearSearch,
                      controller: _search,
                      onChanged: cubit.search,
                      hint: t.help.search,
                    ),
                    const SizedBox(height: BirkaTokens.spaceXl),
                    SectionLabel(t.help.questions, color: colors.textMuted),
                    const SizedBox(height: BirkaTokens.spaceSm),
                    GlassListGroup(
                      children: [
                        for (final (index, question) in shown)
                          _Question(
                            key: ValueKey(index),
                            question: question,
                            open: state.open == index,
                            onTap: () => cubit.toggle(index),
                          ),
                        if (shown.isEmpty)
                          Padding(
                            key: const ValueKey('nothing'),
                            padding: const EdgeInsets.all(BirkaTokens.spaceMd),
                            child: Text(
                              t.help.nothingFound,
                              style: styles.body.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: BirkaTokens.spaceXl),
                    SectionLabel(t.help.contact, color: colors.textMuted),
                    const SizedBox(height: BirkaTokens.spaceSm),
                    GlassListGroup(
                      children: [
                        for (final (kind, color) in [
                          (LetterKind.question, colors.accent),
                          (LetterKind.bug, colors.negative),
                          (
                            LetterKind.idea,
                            const Color(BirkaTokens.colorPaletteAmber),
                          ),
                        ])
                          GlassListRow(
                            leading: DotBadge(color: color),
                            title: letterWayLabel(kind),
                            subtitle: letterWayText(kind),
                            subtitleLines: 2,
                            trailing: BirkaIcon(
                              BirkaGlyph.chevron,
                              size: 18,
                              color: colors.textSubtle,
                            ),
                            onTap: () => unawaited(cubit.compose(kind)),
                          ),
                        GlassListRow(
                          leading: DotBadge(color: colors.textSecondary),
                          title: t.help.github,
                          subtitle: t.help.githubText,
                          subtitleLines: 2,
                          trailing: BirkaIcon(
                            BirkaGlyph.rise,
                            size: 18,
                            color: colors.textSubtle,
                          ),
                          onTap: () => unawaited(cubit.openIssues()),
                        ),
                      ],
                    ),
                    if (about != null) ...[
                      const SizedBox(height: BirkaTokens.spaceLg),
                      Text(
                        aboutLine(about),
                        textAlign: TextAlign.center,
                        style: styles.caption.copyWith(
                          color: colors.textSubtle,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Shows all that [letter] holds and asks whether the mail app gets it.
  Future<void> _offer(BuildContext context, HelpLetter letter) async {
    final cubit = context.read<HelpCubit>();
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final caption = styles.caption.copyWith(color: colors.text);
    TextSpan field(String name, String value) => TextSpan(
      children: [
        TextSpan(
          text: '$name: ',
          style: TextStyle(color: colors.textMuted),
        ),
        TextSpan(text: value),
      ],
    );
    final send = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: colors.background,
      builder: (context) => ChoiceSheet(
        title: letterTitle(letter.kind),
        children: [
          Text(
            t.help.letterText,
            style: styles.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          GlassSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(field(t.help.to, letter.address), style: caption),
                const SizedBox(height: BirkaTokens.spaceXxs),
                Text.rich(
                  field(t.help.subject, letter.subject),
                  style: caption,
                ),
                const SizedBox(height: BirkaTokens.spaceSm),
                SizedBox(
                  height: 1,
                  child: ColoredBox(color: colors.hairline),
                ),
                const SizedBox(height: BirkaTokens.spaceSm),
                Text(letter.body, style: caption),
              ],
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceSm),
          Text(
            t.help.letterPrivacy,
            style: styles.caption.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
          BirkaButton(
            label: t.help.openMail,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          BirkaButton(
            label: t.help.cancel,
            quiet: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    if (send ?? false) {
      await cubit.send();
    } else {
      cubit.dismiss();
    }
  }
}

/// A common question. Its answer opens under it, and the chevron turns.
class _Question extends StatelessWidget {
  const _Question({
    required this.question,
    required this.open,
    required this.onTap,
    super.key,
  });

  final HelpQuestion question;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return Semantics(
      button: true,
      expanded: open,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(BirkaTokens.spaceMd),
          child: AnimatedColumn(
            children: [
              Row(
                key: const ValueKey('question'),
                children: [
                  Expanded(
                    child: Text(
                      question.question,
                      style: styles.bodyStrong.copyWith(color: colors.text),
                    ),
                  ),
                  const SizedBox(width: BirkaTokens.spaceSm),
                  AnimatedRotation(
                    // The chevron points down, and up once the answer shows.
                    turns: open ? 0.75 : 0.25,
                    duration: BirkaMotion.reduced(context)
                        ? Duration.zero
                        : BirkaMotion.base,
                    curve: BirkaMotion.standardCurve,
                    child: BirkaIcon(
                      BirkaGlyph.chevron,
                      size: 16,
                      color: colors.textSubtle,
                    ),
                  ),
                ],
              ),
              if (open)
                Padding(
                  key: const ValueKey('answer'),
                  padding: const EdgeInsets.only(top: BirkaTokens.spaceXs),
                  child: Text(
                    question.answer,
                    style: styles.body.copyWith(color: colors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
