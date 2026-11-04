import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:inbox_common/inbox_common.dart';
import 'package:inbox_jaspr/inbox_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The inbox: what an import leaves to sort (ADR 0022). It has a way back
/// of its own, so the page stands without the tabs of the site.
@client
class InboxIsland extends StatefulComponent {
  /// Creates the island.
  const InboxIsland({super.key});

  @override
  State<InboxIsland> createState() => _InboxIslandState();
}

class _InboxIslandState extends DataIslandState<InboxIsland> {
  @override
  SitePage get page => SitePage.more;

  @override
  String get pageName => t.inbox.title;

  @override
  String get failure => t.inbox.failed;

  @override
  Component get header => GlassPageHeader(title: t.inbox.title);

  @override
  bool get standsAlone => true;

  @override
  Component buildPage(BuildContext context) {
    return BlocProvider<InboxCubit>(
      create: (_) => getIt(),
      child: const InboxPage(backHref: 'more/'),
    );
  }
}
