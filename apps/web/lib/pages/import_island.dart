import 'dart:async';

import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:import_common/import_common.dart';
import 'package:import_jaspr/import_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart'
    show SchedulesRepository, repeatNames;

/// The import of statements, step by step (ADR 0021). The steps have a way
/// back of their own, so the page stands without the tabs of the site.
@client
class ImportIsland extends StatefulComponent {
  /// Creates the island.
  const ImportIsland({super.key});

  @override
  State<ImportIsland> createState() => _ImportIslandState();
}

class _ImportIslandState extends DataIslandState<ImportIsland> {
  @override
  SitePage get page => SitePage.more;

  @override
  String get pageName => t.imports.title;

  @override
  String get failure => t.imports.failed;

  @override
  Component get header => GlassPageHeader(title: t.imports.title);

  @override
  bool get standsAlone => true;

  @override
  Component buildPage(BuildContext context) {
    return BlocProvider<ImportCubit>(
      create: (_) {
        final cubit = getIt<ImportCubit>();
        unawaited(cubit.start());
        return cubit;
      },
      child: ImportPage(
        backHref: 'more/',
        operationsHref: 'operations/',
        inboxHref: 'inbox/',
        schedulesHref: 'schedules/',
        repeats: () => repeatNames(getIt<SchedulesRepository>()),
        onStepChanged: () => scrollPageTo(0),
      ),
    );
  }
}
