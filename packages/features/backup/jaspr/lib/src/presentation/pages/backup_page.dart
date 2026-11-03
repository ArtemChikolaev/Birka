import 'dart:async';

import 'package:backup_common/backup_common.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The data of this browser: where the ledger lives, its copy in a file, the
/// export of its operations and the wipe (ADR 0016).
///
/// The questions before a restore and a wipe stand on the page in place of
/// its buttons. It needs a [BackupCubit] above it.
class BackupPage extends StatefulComponent {
  /// Creates the page.
  const BackupPage({this.note, this.clock = DateTime.now, super.key});

  /// A quiet line about where the data lives, such as whether the browser
  /// keeps it.
  final String? note;

  /// What the time is now, which tests can fix.
  final DateTime Function() clock;

  @override
  State<BackupPage> createState() => _BackupPageState();

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.backup__stored').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
        'padding': 'var(--space-xxs)',
      },
    ),
    css('.backup__where').styles(
      raw: {
        'align-items': 'flex-start',
        'display': 'flex',
        'gap': 'var(--space-md)',
      },
    ),
    css('.backup__where-text').styles(
      raw: {
        'display': 'flex',
        'flex': '1',
        'flex-direction': 'column',
        'gap': 'var(--space-xxs)',
        'min-width': '0',
      },
    ),
    css('.backup__title').styles(
      raw: {'color': 'var(--color-text)', 'margin': '0'},
    ),
    css('.backup__text').styles(
      raw: {'color': 'var(--color-text-secondary)', 'margin': '0'},
    ),
    css('.backup__last').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
      },
    ),
    // A new copy turns the dot green.
    css('.backup__dot').styles(
      raw: {
        'background': 'var(--color-palette-amber)',
        'border-radius': '50%',
        'flex': 'none',
        'height': 'var(--space-xs)',
        'transition': 'background var(--duration-base) var(--easing-fade)',
        'width': 'var(--space-xs)',
      },
    ),
    css('.backup__dot--fresh').styles(
      raw: {'background': 'var(--color-accent)'},
    ),
    // A new line fades in over the old one's place.
    css('.backup__fresh').styles(
      raw: {
        'animation': 'backup-fresh var(--duration-base) var(--easing-fade)',
      },
    ),
    css.keyframes('backup-fresh', {
      'from': const Styles(raw: {'opacity': '0'}),
    }),
    css('.backup__counts').styles(
      raw: {
        'display': 'grid',
        'gap': 'var(--space-sm)',
        'grid-template-columns': 'repeat(3, minmax(0, 1fr))',
      },
    ),
    css('.backup__count').styles(
      raw: {'display': 'flex', 'flex-direction': 'column', 'min-width': '0'},
    ),
    css('.backup__label').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.backup__actions').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-xs)',
      },
    ),
    css('.backup__group').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-sm)',
      },
    ),
    css('.backup__group .section-label').styles(
      raw: {'color': 'var(--color-text-muted)'},
    ),
    css('.backup__row-icon').styles(
      raw: {
        'color': 'var(--color-text-muted)',
        'flex': 'none',
        'height': '18px',
        'width': '18px',
      },
    ),
    css('.backup__question').styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'var(--space-md)',
        'padding': 'var(--space-xxs)',
      },
    ),
    css('.backup__file').styles(
      raw: {
        'align-items': 'center',
        'display': 'flex',
        'gap': 'var(--space-sm)',
        'min-width': '0',
      },
    ),
    css('.backup__file-name').styles(
      raw: {
        'color': 'var(--color-text)',
        'overflow': 'hidden',
        'text-overflow': 'ellipsis',
        'white-space': 'nowrap',
      },
    ),
    css('.backup__note').styles(
      raw: {'color': 'var(--color-text-subtle)', 'margin': '0'},
    ),
    css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), [
      css('.backup__dot').styles(raw: {'transition': 'none'}),
    ]),
  ];
}

class _BackupPageState extends State<BackupPage> {
  /// Whether the question before a wipe stands open.
  bool _askingToWipe = false;

  /// The notice on screen, if any, and how many came before it, which gives
  /// each its own message.
  BackupNotice? _notice;
  int _notices = 0;

  @override
  Component build(BuildContext context) {
    final cubit = context.read<BackupCubit>();
    return BlocConsumer<BackupCubit, BackupState>(
      listenWhen: (previous, current) =>
          current.notice != null && current.notice != previous.notice,
      listener: (context, state) => setState(() {
        _notice = state.notice;
        _notices++;
      }),
      builder: (context, state) {
        final idle = state.task == null;
        final offer = state.offer;
        final notice = _notice;
        return BirkaColumn(
          children: [
            GlassPageHeader(title: t.backup.title),
            _stored(state),
            if (offer != null)
              _askToRestore(cubit, offer)
            else if (_askingToWipe)
              _askToWipe(cubit)
            else
              div(classes: 'backup__actions', [
                BirkaButton(
                  label: t.backup.save,
                  onPressed: idle ? () => unawaited(cubit.save()) : null,
                ),
                BirkaButton(
                  label: t.backup.restore,
                  quiet: true,
                  onPressed: idle ? () => unawaited(cubit.open()) : null,
                ),
              ]),
            section(classes: 'backup__group', [
              SectionLabel(t.backup.export),
              GlassListGroup(
                children: [
                  GlassListRow(
                    leading: const GlyphBadge(
                      glyph: BirkaGlyph.file,
                      color: 'var(--color-palette-sky)',
                    ),
                    title: t.backup.exportTitle,
                    subtitle: t.backup.exportText,
                    subtitleLines: 2,
                    trailing: const span(classes: 'backup__row-icon', [
                      BirkaIcon(BirkaGlyph.download),
                    ]),
                    onTap: idle ? () => unawaited(cubit.export()) : null,
                  ),
                ],
              ),
            ]),
            section(classes: 'backup__group', [
              SectionLabel(t.backup.records),
              GlassListGroup(
                children: [
                  GlassListRow(
                    title: t.backup.wipe,
                    danger: true,
                    onTap: idle
                        ? () => setState(() => _askingToWipe = true)
                        : null,
                  ),
                ],
              ),
            ]),
            p(classes: 'text-caption backup__note', [
              .text(t.backup.filesNoteSite),
            ]),
            if (notice != null)
              GlassToast(
                noticeLabel(notice, now: component.clock()),
                key: ValueKey(_notices),
                trouble: notice.isTrouble,
                onGone: () => setState(() => _notice = null),
              ),
          ],
        );
      },
    );
  }

  /// Where the ledger lives, when it was last copied and how much it holds.
  Component _stored(BackupState state) {
    final lastCopyAt = state.lastCopyAt;
    final counts = state.counts;
    final note = component.note;
    final last = lastCopyAt == null
        ? t.backup.noCopyYet
        : t.backup.lastCopy(
            when: copyMomentLabel(lastCopyAt, now: component.clock()),
          );
    return GlassSurface(
      child: div(classes: 'backup__stored', [
        div(classes: 'backup__where', [
          const GlyphBadge(
            glyph: BirkaGlyph.phone,
            color: 'var(--color-accent)',
            size: 44,
          ),
          div(classes: 'backup__where-text', [
            h2(classes: 'text-heading backup__title', [
              .text(t.backup.storedTitle),
            ]),
            p(classes: 'text-body backup__text', [.text(t.backup.storedText)]),
            if (note != null)
              p(classes: 'text-caption backup__text', [.text(note)]),
          ]),
        ]),
        div(classes: 'backup__last', [
          span(
            classes: lastCopyAt == null
                ? 'backup__dot'
                : 'backup__dot backup__dot--fresh',
            const [],
          ),
          span(
            key: ValueKey(last),
            classes: 'text-caption backup__text backup__fresh',
            [.text(last)],
          ),
        ]),
        div(classes: 'backup__counts', [
          for (final (label, count) in [
            (t.backup.operations, counts?.transactions),
            (t.backup.accounts, counts?.accounts),
            (t.backup.categories, counts?.categories),
          ])
            div(classes: 'backup__count', [
              span(classes: 'text-caption backup__label', [.text(label)]),
              span(classes: 'text-heading backup__title', [
                .text(count == null ? '—' : formatCount(count)),
              ]),
            ]),
        ]),
      ]),
    );
  }

  /// Asks whether the copy on offer replaces the ledger.
  Component _askToRestore(BackupCubit cubit, CopyOffer offer) {
    return GlassSurface(
      child: div(classes: 'backup__question', [
        h2(classes: 'text-heading backup__title', [
          .text(t.backup.restoreTitle),
        ]),
        p(classes: 'text-body backup__text', [.text(t.backup.restoreText)]),
        div(classes: 'backup__file', [
          const GlyphBadge(
            glyph: BirkaGlyph.file,
            color: 'var(--color-palette-violet)',
          ),
          div(classes: 'backup__where-text', [
            span(classes: 'text-body-strong backup__file-name', [
              .text(offer.fileName),
            ]),
            span(classes: 'text-caption backup__label', [
              .text(offerLabel(offer, now: component.clock())),
            ]),
          ]),
        ]),
        div(classes: 'backup__actions', [
          BirkaButton(
            label: t.backup.replace,
            danger: true,
            onPressed: () => unawaited(cubit.restore()),
          ),
          BirkaButton(
            label: t.backup.cancel,
            quiet: true,
            onPressed: cubit.dismiss,
          ),
        ]),
      ]),
    );
  }

  /// Asks whether to delete everything, and offers a copy first.
  Component _askToWipe(BackupCubit cubit) {
    void answered(Future<void> Function()? then) {
      setState(() => _askingToWipe = false);
      if (then != null) unawaited(then());
    }

    return GlassSurface(
      child: div(classes: 'backup__question', [
        h2(classes: 'text-heading backup__title', [.text(t.backup.wipeTitle)]),
        p(classes: 'text-body backup__text', [.text(t.backup.wipeText)]),
        div(classes: 'backup__actions', [
          BirkaButton(
            label: t.backup.saveFirst,
            quiet: true,
            onPressed: () => answered(cubit.save),
          ),
          BirkaButton(
            label: t.backup.wipeAll,
            danger: true,
            onPressed: () => answered(cubit.wipe),
          ),
          BirkaButton(
            label: t.backup.cancel,
            quiet: true,
            onPressed: () => answered(null),
          ),
        ]),
      ]),
    );
  }
}
