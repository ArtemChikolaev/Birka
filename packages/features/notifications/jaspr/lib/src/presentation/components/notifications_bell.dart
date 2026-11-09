import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:notifications_common/notifications_common.dart';

/// The bell in the header of the overview (ADR 0026): a round of glass with
/// the count of the new notices on its corner, a link to the feed at [href].
/// It needs a [NotificationsSummaryCubit] above it.
class NotificationsBell extends StatelessComponent {
  /// Creates the bell.
  const NotificationsBell({required this.href, super.key});

  /// Where the feed of notices opens.
  final String href;

  @override
  Component build(BuildContext context) {
    return BlocBuilder<NotificationsSummaryCubit, int>(
      builder: (context, count) => GlassIconButton(
        glyph: BirkaGlyph.bell,
        label: count == 0
            ? t.notifications.bell
            : t.notifications.bellNew(n: count, count: formatCount(count)),
        href: href,
        badge: count,
      ),
    );
  }
}
