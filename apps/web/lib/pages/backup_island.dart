import 'package:backup_common/backup_common.dart';
import 'package:backup_jaspr/backup_jaspr.dart';
import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/browser_settings_store.dart';
import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The data of this browser: its copy in a file, the export of its operations
/// and the wipe (ADR 0016).
@client
class BackupIsland extends StatefulComponent {
  /// Creates the island.
  const BackupIsland({super.key});

  @override
  State<BackupIsland> createState() => _BackupIslandState();
}

class _BackupIslandState extends DataIslandState<BackupIsland> {
  static const _settings = BrowserSettingsStore();

  @override
  SitePage get page => SitePage.more;

  @override
  String get pageName => t.backup.title;

  @override
  String get failure => t.backup.failed;

  @override
  Component get header => GlassPageHeader(title: t.backup.title);

  @override
  Component buildPage(BuildContext context) {
    return BlocProvider<BackupCubit>(
      create: (_) => getIt(),
      child: BackupPage(
        wide: wide,
        note: storageNote,
        demo: demoStateIn(_settings).isOn,
        onDemoChanged: (on) async {
          await turnDemo(_settings, on: on);
          // The other ledger opens with the overview, as a page of its own.
          openSitePage('overview/');
        },
      ),
    );
  }
}
