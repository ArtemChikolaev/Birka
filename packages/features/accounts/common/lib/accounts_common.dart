/// The accounts feature in pure Dart: the list with its totals and the form,
/// shared by both hosts (ADR 0006).
library;

export 'package:ledger/ledger.dart'
    show Account, AccountArt, AccountBalance, AccountType;

export 'src/di/register_accounts.dart';
export 'src/domain/account_draft.dart';
export 'src/domain/accounts_overview.dart';
export 'src/domain/accounts_repository.dart';
export 'src/domain/offered_currencies.dart';
export 'src/presentation/account_form_cubit.dart';
export 'src/presentation/accounts_cubit.dart';
