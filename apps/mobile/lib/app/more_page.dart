import 'package:birka_mobile/app/app_version.dart';
import 'package:birka_mobile/app/router.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:help_common/help_common.dart';
import 'package:inbox_flutter/inbox_flutter.dart';
import 'package:l10n/l10n.dart';
import 'package:settings_flutter/settings_flutter.dart';

/// The tab with everything that has no tab of its own, and the settings.
///
/// It needs an `InboxSummaryCubit` above it for the way to the inbox.
class MorePage extends StatelessWidget {
  /// Creates the page; [links] open the code of Birka, and [onImport]
  /// starts the import of a statement.
  const MorePage({required this.links, required this.onImport, super.key});

  /// The ways out of the app.
  final HelpLinks links;

  /// Starts the import of a statement over the page in the context it gets.
  final Future<void> Function(BuildContext context) onImport;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          BirkaTokens.spaceLg,
          BirkaTokens.spaceLg,
          BirkaTokens.spaceLg,
          GlassNavBar.clearance + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Text(t.app.more, style: styles.title.copyWith(color: colors.text)),
          const SizedBox(height: BirkaTokens.spaceLg),
          InboxTile(onOpen: () => context.push(Paths.inbox)),
          const SizedBox(height: BirkaTokens.spaceSm),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  color: const Color(BirkaTokens.colorPaletteGreen),
                  label: t.accounts.title,
                  onTap: () => context.push(Paths.accounts),
                ),
              ),
              const SizedBox(width: BirkaTokens.spaceSm),
              Expanded(
                child: _Tile(
                  color: const Color(BirkaTokens.colorPaletteAmber),
                  label: t.categories.title,
                  onTap: () => context.push(Paths.categories),
                ),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceSm),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  color: const Color(BirkaTokens.colorPaletteSky),
                  label: t.app.import,
                  onTap: () => onImport(context),
                ),
              ),
              const SizedBox(width: BirkaTokens.spaceSm),
              Expanded(
                child: _Tile(
                  color: const Color(BirkaTokens.colorPaletteViolet),
                  label: t.app.data,
                  onTap: () => context.push(Paths.backup),
                ),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
          const SettingsSection(),
          const SizedBox(height: BirkaTokens.spaceLg),
          SectionLabel(t.app.support, color: colors.textMuted),
          const SizedBox(height: BirkaTokens.spaceXs),
          GlassListGroup(
            children: [
              GlassListRow(
                title: t.app.help,
                trailing: BirkaIcon(
                  BirkaGlyph.chevron,
                  size: 18,
                  color: colors.textSubtle,
                ),
                onTap: () => context.push(Paths.help),
              ),
            ],
          ),
          const SizedBox(height: BirkaTokens.spaceLg),
          _Footer(links: links),
        ],
      ),
    );
  }
}

/// The end of the page: the version, where the records live, the code and
/// where the rates come from.
class _Footer extends StatelessWidget {
  const _Footer({required this.links});

  final HelpLinks links;

  Future<void> _openCode(BuildContext context) async {
    if (await links.open(codePage)) return;
    if (context.mounted) showGlassToast(context, t.help.noPage, trouble: true);
  }

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final caption = styles.caption.copyWith(color: colors.textSubtle);
    return Column(
      children: [
        Text(
          'Birka $appVersion · ${t.app.keptOnDevice}',
          style: caption,
          textAlign: TextAlign.center,
        ),
        Semantics(
          link: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openCode(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BirkaTokens.spaceMd,
                vertical: BirkaTokens.spaceXs,
              ),
              child: Text(
                t.app.sourceCode,
                style: caption.copyWith(
                  color: colors.textMuted,
                  decoration: TextDecoration.underline,
                  decorationColor: colors.textMuted,
                ),
              ),
            ),
          ),
        ),
        Text(
          '${t.settings.ratesCredit}: cbr-xml-daily.ru',
          style: caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// A square of glass with a colored mark. Without [onTap] it waits for its
/// feature and says so.
class _Tile extends StatelessWidget {
  const _Tile({required this.color, required this.label, this.onTap});

  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DotBadge(color: color),
              const SizedBox(height: BirkaTokens.spaceSm),
              // On a narrow phone the mark takes its own line.
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: BirkaTokens.spaceXs,
                  children: [
                    Text(
                      label,
                      style: styles.bodyStrong.copyWith(color: colors.text),
                    ),
                    if (onTap == null)
                      Text(
                        t.app.soon.toUpperCase(),
                        style: styles.label.copyWith(color: colors.textSubtle),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
