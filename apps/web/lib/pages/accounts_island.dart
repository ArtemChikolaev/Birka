import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_jaspr/accounts_jaspr.dart';
import 'package:birka_web/app/data_island.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The accounts in the browser. The address `accounts/#new` opens a new
/// account and `accounts/#<id>` an existing one.
@client
class AccountsIsland extends StatefulComponent {
  /// Creates the island.
  const AccountsIsland({super.key});

  @override
  State<AccountsIsland> createState() => _AccountsIslandState();
}

class _AccountsIslandState extends DataIslandState<AccountsIsland> {
  static const _home = './';
  static const _list = 'accounts/';
  static const _newAccount = 'new';

  @override
  String get pageName => t.accounts.title;

  @override
  String get failure => t.accounts.failed;

  @override
  Component get header => GlassPageHeader(
    backHref: _home,
    backLabel: t.accounts.back,
    addHref: '$_list#$_newAccount',
    addLabel: t.accounts.add,
  );

  @override
  Component buildPage(BuildContext context) {
    if (fragment.isEmpty) {
      return BlocProvider<AccountsCubit>(
        create: (_) => getIt(),
        child: AccountsPage(
          backHref: _home,
          addHref: '$_list#$_newAccount',
          hrefOf: (id) => '$_list#$id',
          note: storageNote,
        ),
      );
    }
    final id = fragment == _newAccount ? null : fragment;
    return BlocProvider<AccountFormCubit>(
      key: ValueKey(fragment),
      create: (_) => getIt(param1: id),
      child: AccountFormPage(onClose: closeForm),
    );
  }
}
