import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:notifications_common/notifications_common.dart';

/// The bell in the header of the overview (ADR 0026): a round of glass with
/// the count of the new notices on its corner, which [onOpen] follows to the
/// feed. It needs a [NotificationsSummaryCubit] above it.
class NotificationsBell extends StatelessWidget {
  /// Creates the bell.
  const NotificationsBell({required this.onOpen, super.key});

  /// Opens the feed of notices.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsSummaryCubit, int>(
      builder: (context, count) => GlassIconButton(
        glyph: BirkaGlyph.bell,
        label: count == 0
            ? t.notifications.bell
            : t.notifications.bellNew(n: count, count: formatCount(count)),
        badge: count,
        onPressed: onOpen,
      ),
    );
  }
}
