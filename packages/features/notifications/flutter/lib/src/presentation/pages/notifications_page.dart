import 'dart:async';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:ledger/ledger.dart';
import 'package:notifications_common/notifications_common.dart';

/// The color of a payment, as on the tile of a reminder.
const _payments = Color(BirkaTokens.colorPaletteAmber);

/// The color of an import of a statement.
const _imports = Color(BirkaTokens.colorPaletteSky);

/// The color of the day of a debt, which comes as a payment does.
const _debts = Color(BirkaTokens.colorPaletteAmber);

/// The color of what waits for the person.
const _waits = Color(BirkaTokens.colorPaletteAmber);

/// Opens [place] of a notice, with the id of its payment when it has one.
typedef OpenNoticePlace = void Function(NoticePlace place, String? id);

/// The feed of notices on the phone, as its board draws it (ADR 0026): the
/// new ones on top with a dot, which a tap opens where they lead and «Прочитать
/// все» moves into the history, and the history below by days, each line in
/// the color of what became of its notice. Chips narrow the feed to one
/// source while it has two or more. It needs a [NotificationsCubit] above it.
class NotificationsPage extends StatefulWidget {
  /// Creates the page, which [onBack] leaves and [onOpen] leaves for the
  /// place of a notice.
  const NotificationsPage({
    required this.onBack,
    required this.onOpen,
    super.key,
  });

  /// Leaves the page.
  final VoidCallback onBack;

  /// Opens where a notice leads.
  final OpenNoticePlace onOpen;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<NotificationsCubit>().calendarChecked(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _open(NotificationsCubit cubit, Notice notice) async {
    final place = await cubit.open(notice);
    if (place != null && mounted) widget.onOpen(place.place, place.id);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) => ListView(
              padding: EdgeInsets.fromLTRB(
                BirkaTokens.spaceLg,
                BirkaTokens.spaceLg,
                BirkaTokens.spaceLg,
                BirkaTokens.spaceXxl + bottom,
              ),
              children: [
                BackHeader(
                  label: t.notifications.title,
                  backLabel: t.notifications.back,
                  onBack: widget.onBack,
                ),
                const SizedBox(height: BirkaTokens.spaceLg),
                ...switch (state.status) {
                  NotificationsStatus.loading => const <Widget>[],
                  _ when state.notices.isEmpty => [const _Empty()],
                  _ => _feed(context, state),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _feed(BuildContext context, NotificationsState state) {
    final cubit = context.read<NotificationsCubit>();
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final fresh = state.fresh;
    return [
      if (state.sources.isNotEmpty) ...[
        Semantics(
          label: t.notifications.filtersLabel,
          container: true,
          child: Wrap(
            spacing: BirkaTokens.spaceXs,
            runSpacing: BirkaTokens.spaceXs,
            children: [
              for (final source in <NoticeSource?>[null, ...state.sources])
                BirkaChip(
                  label: t.notifications.filters[source?.name ?? 'all'] ?? '',
                  selected: state.source == source,
                  // A source with nothing new shows no count.
                  count: switch (state.newOf(source)) {
                    0 => null,
                    final count => count,
                  },
                  compact: true,
                  onTap: () => cubit.pick(source),
                ),
            ],
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceLg),
      ],
      // The new ones close into the days of the history when they are read,
      // and another source changes the feed at once.
      AnimatedColumn(
        key: ValueKey(state.source),
        children: [
          if (fresh.isNotEmpty)
            Padding(
              key: const ValueKey('fresh'),
              padding: const EdgeInsets.only(bottom: BirkaTokens.spaceLg),
              child: _Section(
                label: t.notifications.fresh(count: formatCount(fresh.length)),
                action: AccentLink(
                  label: t.notifications.readAll,
                  chevron: false,
                  onTap: () => unawaited(cubit.readAll()),
                ),
                children: [
                  for (final notice in fresh)
                    _NoticeRow(
                      key: ValueKey(notice.id),
                      notice: notice,
                      today: state.today,
                      fresh: true,
                      leads: state.placeOf(notice) != null,
                      onTap: () => unawaited(_open(cubit, notice)),
                    ),
                ],
              ),
            ),
          for (final day in state.days)
            Padding(
              key: ValueKey(day.day),
              padding: const EdgeInsets.only(bottom: BirkaTokens.spaceLg),
              child: _Section(
                label: noticeDayHeading(day.day, today: state.today),
                children: [
                  for (final notice in day.notices)
                    _NoticeRow(
                      key: ValueKey(notice.id),
                      notice: notice,
                      today: state.today,
                      onTap: state.placeOf(notice) == null
                          ? null
                          : () => unawaited(_open(cubit, notice)),
                    ),
                ],
              ),
            ),
        ],
      ),
      Text(
        t.notifications.keeps,
        textAlign: TextAlign.center,
        style: styles.caption.copyWith(color: colors.textSubtle),
      ),
    ];
  }
}

/// A group of notices under its label: the new ones or one day.
class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.children,
    this.action,
  });

  final String label;
  final Widget? action;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final action = this.action;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BirkaTokens.spaceXxs,
          ),
          child: Row(
            children: [
              Expanded(
                child: SectionLabel(label, color: colors.textSecondary),
              ),
              ?action,
            ],
          ),
        ),
        const SizedBox(height: BirkaTokens.spaceXs),
        GlassListGroup(children: children),
      ],
    );
  }
}

/// A notice: the tile of its source, what it is about and, under it, when
/// its time comes while it is new, or what became of it in the history.
class _NoticeRow extends StatelessWidget {
  const _NoticeRow({
    required this.notice,
    required this.today,
    required this.onTap,
    this.fresh = false,
    this.leads = false,
    super.key,
  });

  final Notice notice;
  final CivilDate today;
  final bool fresh;

  /// Whether a tap leads somewhere, which a new one shows with a chevron.
  final bool leads;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    final (line, tone) = noticeLine(notice, today: today, fresh: fresh);
    final tile = switch (notice.source) {
      NoticeSource.payment => const GlyphBadge(
        glyph: BirkaGlyph.calendar,
        color: _payments,
      ),
      NoticeSource.debt => const GlyphBadge(
        glyph: BirkaGlyph.people,
        color: _debts,
      ),
      NoticeSource.import => const GlyphBadge(
        glyph: BirkaGlyph.download,
        color: _imports,
      ),
    };
    final moment = Text(
      fresh ? noticeMoment(notice, today: today) : clockOf(notice.at),
      style: styles.caption.copyWith(
        color: fresh ? colors.accent : colors.textSubtle,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return GlassListRow(
      title: noticeTitle(notice, today: today),
      subtitle: line,
      subtitleLines: fresh ? 1 : 2,
      subtitleColor: fresh
          ? colors.textSecondary
          : switch (tone) {
              NoticeTone.done => colors.positive,
              NoticeTone.waits => _waits,
              NoticeTone.left => colors.textSubtle,
              NoticeTone.plain => null,
            },
      leading: fresh
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NewDot(color: colors.accent),
                const SizedBox(width: BirkaTokens.spaceSm),
                tile,
              ],
            )
          : tile,
      trailing: fresh && leads
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                moment,
                const SizedBox(height: BirkaTokens.spaceXxs),
                BirkaIcon(
                  BirkaGlyph.chevron,
                  size: BirkaTokens.spaceMd,
                  color: colors.textMuted,
                ),
              ],
            )
          : moment,
      onTap: onTap,
    );
  }
}

/// The glowing dot of a notice the person has not read.
class _NewDot extends StatelessWidget {
  const _NewDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: BirkaTokens.spaceXs,
      height: BirkaTokens.spaceXs,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.7),
            blurRadius: BirkaTokens.spaceXs,
          ),
        ],
      ),
    );
  }
}

/// What the feed says while nothing has come.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    final styles = BirkaTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: BirkaTokens.spaceXxl * 3),
      child: Column(
        children: [
          GlyphBadge(
            glyph: BirkaGlyph.bell,
            color: colors.accent,
            size: BirkaTokens.sizeTouchTarget + BirkaTokens.spaceSm,
          ),
          const SizedBox(height: BirkaTokens.spaceMd),
          Text(
            t.notifications.emptyTitle,
            textAlign: TextAlign.center,
            style: styles.heading.copyWith(color: colors.text),
          ),
          const SizedBox(height: BirkaTokens.spaceXs),
          Text(
            t.notifications.emptyText,
            textAlign: TextAlign.center,
            style: styles.body.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
