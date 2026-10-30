import 'package:birka_mobile/app/router.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';

/// The tab with everything that has no tab of its own.
class MorePage extends StatelessWidget {
  /// Creates the page.
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(BirkaTokens.spaceLg),
        children: [
          Text(t.app.more, style: styles.title.copyWith(color: colors.text)),
          const SizedBox(height: BirkaTokens.spaceLg),
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
                ),
              ),
              const SizedBox(width: BirkaTokens.spaceSm),
              Expanded(
                child: _Tile(
                  color: const Color(BirkaTokens.colorPaletteViolet),
                  label: t.app.backup,
                ),
              ),
            ],
          ),
        ],
      ),
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

  static const double _mark = 36;

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
              Container(
                width: _mark,
                height: _mark,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(BirkaTokens.radiusSm),
                  ),
                ),
                child: Container(
                  width: BirkaTokens.spaceSm,
                  height: BirkaTokens.spaceSm,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: BirkaTokens.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: styles.bodyStrong.copyWith(color: colors.text),
                    ),
                  ),
                  if (onTap == null)
                    Text(
                      t.app.soon.toUpperCase(),
                      style: styles.label.copyWith(color: colors.textSubtle),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
