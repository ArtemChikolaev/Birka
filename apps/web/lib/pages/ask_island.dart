import 'package:ask_common/ask_common.dart';
import 'package:ask_jaspr/ask_jaspr.dart';
import 'package:birka_web/app/ask_focus.dart';
import 'package:birka_web/app/browser.dart';
import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart' show SchedulesCubit;
import 'package:schedules_jaspr/schedules_jaspr.dart';

/// «Спросить» in the browser (ADR 0028). The question stands in the
/// fragment of the address, `ask/#кафе%20в%20октябре`, so that the way back
/// from the operations of an answer finds it again, and another fragment
/// asks another question; the tabs stay with it. The key `/` puts the focus
/// into its field.
@client
class AskIsland extends StatefulComponent {
  /// Creates the island.
  const AskIsland({super.key});

  @override
  State<AskIsland> createState() => _AskIslandState();
}

class _AskIslandState extends DataIslandState<AskIsland> {
  @override
  SitePage get page => SitePage.overview;

  @override
  String get pageName => t.ask.title;

  @override
  String get failure => t.ask.failed;

  @override
  Component get header => GlassPageHeader(title: t.ask.title);

  @override
  bool get fragmentKeepsTabs => true;

  @override
  void onSlashKey() => focusElement('.glass-search__input');

  @override
  Component buildPage(BuildContext context) {
    return BlocProvider<AskCubit>(
      create: (_) {
        final cubit = getIt<AskCubit>();
        final question = questionOf(fragment);
        if (question.isNotEmpty) cubit.ask(question);
        return cubit;
      },
      child: AskPage(
        question: questionOf(fragment),
        wide: wide,
        onQuestion: (question) => replaceAddressFragment(
          question.isEmpty ? '' : Uri.encodeComponent(question),
        ),
        operationsHref: 'operations/',
        onShowOperations: handFocus,
        hrefOfOperation: (id) => 'operations/#$id',
        hrefOfTag: (id) => 'tags/#$id',
        hrefOfPlace: _hrefOf,
        helpHref: 'help/',
        // What can be spent today and the next payments are the card of
        // the overview.
        fact: (_) => BlocProvider<SchedulesCubit>(
          create: (_) => getIt(),
          child: const SpendingCard(
            paydayHref: 'payday/',
            listHref: 'schedules/',
          ),
        ),
      ),
    );
  }

  /// The pages of the site that an answer names.
  static String? _hrefOf(AskPlace place) => switch (place) {
    AskPlace.payday => 'payday/',
    AskPlace.schedules => 'schedules/',
    AskPlace.tags => 'tags/',
    AskPlace.accounts => 'accounts/',
    AskPlace.categories => 'categories/',
    AskPlace.imports => 'import/',
    AskPlace.inbox => 'inbox/',
    AskPlace.backup => 'data/',
    AskPlace.help => 'help/',
    AskPlace.notifications => 'notifications/',
    AskPlace.reports => 'reports/',
    AskPlace.settings => 'more/',
  };
}
