import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:identity_common/src/domain/account_access.dart';
import 'package:l10n/l10n.dart';

/// The current step in optional account access.
enum AccountStep {
  /// Restoring a previous session.
  loading,

  /// Account service has not been configured for this build.
  unconfigured,

  /// Restoring a session failed and can be retried.
  retry,

  /// Enter an address or continue as a guest.
  email,

  /// Verify a challenge or request a replacement.
  code,

  /// Signed in to this address.
  profile,

  /// Instructions for moving local records.
  copy,
}

/// State of the account page. Codes never become part of the persisted state.
final class IdentityState {
  /// Creates a snapshot.
  const IdentityState(
    this.step, {
    this.email = '',
    this.challenge = '',
    this.busy = false,
    this.issue,
  });

  /// Active view.
  final AccountStep step;

  /// Address bound to the current challenge or session.
  final String email;

  /// Opaque server handle, used only while verifying.
  final String challenge;

  /// An action is in progress.
  final bool busy;

  /// Feedback for the current view.
  final AccountIssue? issue;

  IdentityState _with({bool busy = false, AccountIssue? issue}) =>
      IdentityState(
        step,
        email: email,
        challenge: challenge,
        busy: busy,
        issue: issue,
      );
}

/// Opens only when the person visits the account page.
final class IdentityCubit extends Cubit<IdentityState> {
  /// Restores the session if a service is configured.
  IdentityCubit(this._access)
    : super(
        IdentityState(
          _access == null ? AccountStep.unconfigured : AccountStep.loading,
        ),
      ) {
    if (_access != null) unawaited(restore());
  }
  final AccountAccess? _access;

  Future<void> _run(
    Future<IdentityState> Function(AccountAccess api) action,
  ) async {
    final api = _access;
    if (isClosed || state.busy || api == null) return;
    final prior = state;
    emit(prior._with(busy: true));
    try {
      final next = await action(api);
      if (!isClosed) emit(next);
    } on Object catch (error) {
      if (isClosed) return;
      final issue = error is AccountIssue ? error : AccountIssue.unavailable;
      emit(
        prior.step == AccountStep.loading || prior.step == AccountStep.retry
            ? IdentityState(AccountStep.retry, issue: issue)
            : prior._with(issue: issue),
      );
    }
  }

  /// Checks session validity with the server.
  Future<void> restore() => _run((api) async {
    final email = await api.session();
    return email == null
        ? const IdentityState(AccountStep.email)
        : IdentityState(AccountStep.profile, email: email);
  });

  /// Requests a code for the address or replaces the current challenge.
  Future<void> request(String value) => _run((api) async {
    final email = value.trim();
    if (email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      throw AccountIssue.email;
    }
    final id = await api.request(
      email,
      LocaleSettings.currentLocale.languageCode,
    );
    return IdentityState(AccountStep.code, email: email, challenge: id);
  });

  /// Returns to the address step.
  void editEmail() {
    if (!state.busy) emit(IdentityState(AccountStep.email, email: state.email));
  }

  /// Verifies the entered digits.
  Future<void> verify(String value) => _run((api) async {
    final code = value.trim();
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) throw AccountIssue.code;
    return IdentityState(
      AccountStep.profile,
      email: await api.verify(state.challenge, code),
    );
  });

  /// Opens or closes the transfer instructions for a signed-in person.
  void showCopy({required bool open}) {
    if (state.busy ||
        (state.step != AccountStep.copy && state.step != AccountStep.profile)) {
      return;
    }
    emit(
      IdentityState(
        open ? AccountStep.copy : AccountStep.profile,
        email: state.email,
      ),
    );
  }

  /// Signs out on this device.
  Future<void> logout() => _run((api) async {
    await api.logout();
    return const IdentityState(AccountStep.email);
  });

  @override
  Future<void> close() {
    _access?.close();
    return super.close();
  }
}

/// The localized explanation for an account error.
String accountIssueLabel(AccountIssue issue) => switch (issue) {
  AccountIssue.email => t.identity.badEmail,
  AccountIssue.code => t.identity.badCode,
  AccountIssue.limited => t.identity.limited,
  AccountIssue.cookies => t.identity.cookies,
  AccountIssue.unavailable => t.identity.unavailable,
};

/// Describes the local ledger once the device has supplied both counts.
String? localRecordSummary(int? accounts, int? operations) {
  if (accounts == null || operations == null) return null;
  if (accounts == 0 && operations == 0) return t.identity.empty;
  return t.identity.device(
    accounts: t.backup.accountsCount(n: accounts, count: accounts),
    operations: t.backup.operationsCount(n: operations, count: operations),
  );
}
