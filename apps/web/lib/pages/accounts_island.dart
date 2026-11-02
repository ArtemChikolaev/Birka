import 'dart:async';

import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_jaspr/accounts_jaspr.dart';
import 'package:birka_web/app/data_island.dart';
import 'package:birka_web/components/site_nav.dart';
import 'package:birka_web/pages/operation_views.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:transactions_common/transactions_common.dart' show AccountCubit;
import 'package:transactions_jaspr/transactions_jaspr.dart' show AccountPage;

/// The accounts in the browser. The address `accounts/#new` opens a new
/// account and `accounts/#<id>` the page of one. Over that page
/// `accounts/#<id>/edit` opens its form and `accounts/#<id>/<view>` an
/// operation, with the views of `operations/#`.
@client
class AccountsIsland extends StatefulComponent {
  /// Creates the island.
  const AccountsIsland({super.key});

  @override
  State<AccountsIsland> createState() => _AccountsIslandState();
}

class _AccountsIslandState extends DataIslandState<AccountsIsland>
    with OperationViews {
  static const _new = 'new';
  static const _edit = 'edit';

  AccountCubit? _account;

  @override
  String get address => 'accounts/';

  @override
  SitePage get page => SitePage.more;

  @override
  String get pageName => t.accounts.title;

  @override
  String get failure => t.accounts.failed;

  @override
  Component get header => GlassPageHeader(title: t.accounts.title);

  @override
  void onTabShown() {
    final account = _account;
    if (account != null && !account.isClosed) {
      unawaited(account.calendarChecked());
    }
  }

  @override
  Component buildPage(BuildContext context) {
    return switch (fragment) {
      '' => BlocProvider<AccountsCubit>(
        create: (_) => getIt(),
        child: AccountsPage(
          addHref: '$address#$_new',
          hrefOf: (id) => '$address#$id',
          note: storageNote,
        ),
      ),
      _new => _form(null, closeForm),
      final path => _accountViews(path),
    };
  }

  // The page stays under what opens from it, so that they do not lose its
  // period.
  Component _accountViews(String path) {
    final [id, ...views] = path.split('/');
    return BlocProvider<AccountCubit>(
      key: ValueKey(id),
      create: (_) => _account = getIt(param1: id),
      child: switch (views) {
        [] => AccountPage(
          onClose: closeView,
          editHref: '$address#$id/$_edit',
          hrefOf: (operation) => '$address#$id/$operation',
        ),
        [_edit] => _form(id, () => closeForm(id)),
        [final view, ...] => operationView(view, parent: id),
      },
    );
  }

  Component _form(String? id, VoidCallback onClose) {
    return BlocProvider<AccountFormCubit>(
      key: ValueKey(fragment),
      create: (_) => getIt(param1: id),
      child: AccountFormPage(onClose: onClose),
    );
  }
}
