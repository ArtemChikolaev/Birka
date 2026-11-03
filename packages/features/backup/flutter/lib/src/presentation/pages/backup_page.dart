import 'package:backup_common/backup_common.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

/// The data of this device: where the ledger lives, its copy in a file, the
/// export of its operations and the wipe (ADR 0016).
///
/// It needs a [BackupCubit] above it.
class BackupPage extends StatelessWidget {
  /// Creates the page.
  const BackupPage({
    required this.onBack,
    this.clock = DateTime.now,
    super.key,
  });

  /// Called by the button that goes back.
  final VoidCallback onBack;

  /// What the time is now, which tests can fix.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final cubit = context.read<BackupCubit>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: MultiBlocListener(
            listeners: [
              BlocListener<BackupCubit, BackupState>(
                listenWhen: (previous, current) =>
                    current.notice != null && current.notice != previous.notice,
                listener: (context, state) {
                  final notice = state.notice!;
                  showGlassToast(
                    context,
                    noticeLabel(notice, now: clock()),
                    trouble: notice.isTrouble,
                  );
                },
              ),
              BlocListener<BackupCubit, BackupState>(
                listenWhen: (previous, current) =>
                    current.offer != null && current.offer != previous.offer,
                listener: (context, state) =>
                    _askToRestore(context, state.offer!),
              ),
            ],
            child: BlocBuilder<BackupCubit, BackupState>(
              builder: (context, state) {
                final idle = state.task == null;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    BirkaTokens.spaceLg,
                    BirkaTokens.spaceXs,
                    BirkaTokens.spaceLg,
                    BirkaTokens.spaceXxl,
                  ),
                  children: [
                    _Header(onBack: onBack),
                    const SizedBox(height: BirkaTokens.spaceLg),
                    _Stored(state: state, now: clock()),
                    const SizedBox(height: BirkaTokens.spaceMd),
                    BirkaButton(
                      label: t.backup.save,
                      onPressed: idle ? cubit.save : null,
                    ),
                    const SizedBox(height: BirkaTokens.spaceXs),
                    BirkaButton(
                      label: t.backup.restore,
                      quiet: true,
                      onPressed: idle ? cubit.open : null,
                    ),
                    const SizedBox(height: BirkaTokens.spaceXl),
                    SectionLabel(t.backup.export, color: colors.textMuted),
                    const SizedBox(height: BirkaTokens.spaceSm),
                    GlassListGroup(
                      children: [
                        GlassListRow(
                          leading: const GlyphBadge(
                            glyph: BirkaGlyph.file,
                            color: Color(BirkaTokens.colorPaletteSky),
                          ),
                          title: t.backup.exportTitle,
                          subtitle: t.backup.exportText,
                          subtitleLines: 2,
                          trailing: BirkaIcon(
                            BirkaGlyph.download,
                            size: 18,
                            color: colors.textMuted,
                          ),
                          onTap: idle ? cubit.export : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: BirkaTokens.spaceXl),
                    SectionLabel(t.backup.records, color: colors.textMuted),
                    const SizedBox(height: BirkaTokens.spaceSm),
                    GlassListGroup(
                      children: [
                        GlassListRow(
                          title: t.backup.wipe,
                          danger: true,
                          onTap: idle ? () => _askToWipe(context) : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: BirkaTokens.spaceMd),
                    Text(
                      t.backup.filesNote,
                      style: styles.caption.copyWith(color: colors.textSubtle),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Asks whether the copy on offer replaces the ledger.
  Future<void> _askToRestore(BuildContext context, CopyOffer offer) async {
    final cubit = context.read<BackupCubit>();
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final sure = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: colors.background,
      builder: (context) => ChoiceSheet(
        title: t.backup.restoreTitle,
        children: [
          Text(
            t.backup.restoreText,
            style: styles.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          GlassSurface(
            child: Row(
              children: [
                const GlyphBadge(
                  glyph: BirkaGlyph.file,
                  color: Color(BirkaTokens.colorPaletteViolet),
                ),
                const SizedBox(width: BirkaTokens.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: styles.bodyStrong.copyWith(color: colors.text),
                      ),
                      Text(
                        offerLabel(offer, now: clock()),
                        style: styles.caption.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
          BirkaButton(
            label: t.backup.replace,
            danger: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          BirkaButton(
            label: t.backup.cancel,
            quiet: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    if (sure ?? false) {
      await cubit.restore();
    } else {
      cubit.dismiss();
    }
  }

  /// Asks whether to delete everything, and offers a copy first.
  Future<void> _askToWipe(BuildContext context) async {
    final cubit = context.read<BackupCubit>();
    final colors = BirkaColors.of(context);
    final answer = await showModalBottomSheet<_WipeAnswer>(
      context: context,
      useRootNavigator: true,
      backgroundColor: colors.background,
      builder: (context) => ChoiceSheet(
        title: t.backup.wipeTitle,
        children: [
          Text(
            t.backup.wipeText,
            style: BirkaTextStyles.of(
              context,
            ).body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
          BirkaButton(
            label: t.backup.saveFirst,
            quiet: true,
            onPressed: () => Navigator.of(context).pop(_WipeAnswer.saveFirst),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          BirkaButton(
            label: t.backup.wipeAll,
            danger: true,
            onPressed: () => Navigator.of(context).pop(_WipeAnswer.wipe),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          BirkaButton(
            label: t.backup.cancel,
            quiet: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
    switch (answer) {
      case _WipeAnswer.saveFirst:
        await cubit.save();
      case _WipeAnswer.wipe:
        await cubit.wipe();
      case null:
        break;
    }
  }
}

enum _WipeAnswer { saveFirst, wipe }

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassIconButton(
          glyph: BirkaGlyph.back,
          label: t.backup.back,
          onPressed: onBack,
        ),
        Expanded(
          child: Center(
            child: SectionLabel(
              t.backup.title,
              color: BirkaColors.of(context).textMuted,
            ),
          ),
        ),
        // Keeps the label in the middle.
        const SizedBox(width: BirkaTokens.sizeTouchTarget),
      ],
    );
  }
}

/// Where the ledger lives, when it was last copied and how much it holds.
class _Stored extends StatelessWidget {
  const _Stored({required this.state, required this.now});

  final BackupState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final lastCopyAt = state.lastCopyAt;
    final counts = state.counts;
    return GlassSurface(
      padding: const EdgeInsets.all(BirkaTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlyphBadge(
                glyph: BirkaGlyph.phone,
                color: colors.accent,
                size: 44,
              ),
              const SizedBox(width: BirkaTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.backup.storedTitle,
                      style: styles.heading.copyWith(color: colors.text),
                    ),
                    const SizedBox(height: BirkaTokens.spaceXxs),
                    Text(
                      t.backup.storedText,
                      style: styles.body.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          Row(
            children: [
              // A new copy turns the dot green and the line to its time.
              AnimatedContainer(
                duration: BirkaMotion.reduced(context)
                    ? Duration.zero
                    : BirkaMotion.base,
                width: BirkaTokens.spaceXs,
                height: BirkaTokens.spaceXs,
                decoration: BoxDecoration(
                  color: lastCopyAt == null
                      ? const Color(BirkaTokens.colorPaletteAmber)
                      : colors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: BirkaTokens.spaceSm),
              Expanded(
                child: FadingText(
                  lastCopyAt == null
                      ? t.backup.noCopyYet
                      : t.backup.lastCopy(
                          when: copyMomentLabel(lastCopyAt, now: now),
                        ),
                  style: styles.caption.copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          Row(
            children: [
              for (final (label, count) in [
                (t.backup.operations, counts?.transactions),
                (t.backup.accounts, counts?.accounts),
                (t.backup.categories, counts?.categories),
              ])
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: styles.caption.copyWith(color: colors.textMuted),
                      ),
                      Text(
                        count == null ? '—' : formatCount(count),
                        style: styles.heading.copyWith(color: colors.text),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
