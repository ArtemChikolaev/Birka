import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:identity_common/src/domain/account_access.dart';
import 'package:l10n/l10n.dart';

/// The current step in optional account access.
enum AccountStep {
  /// Checking available methods and the current session.
  loading,

  /// The service has no configured sign-in methods.
  unconfigured,

  /// Session restoration failed.
  retry,

  /// Choose an identifier and request a code.
  entry,

  /// Verify a sign-in or linking challenge.
  code,

  /// Confirm creation of a new phone-based account.
  registration,

  /// Delivery failed or the verified method belongs to another account.
  problem,

  /// Signed in.
  profile,

  /// Local transfer instructions.
  copy,
}

/// A snapshot of the optional account flow.
final class IdentityState {
  /// Creates the current screen.
  const IdentityState(
    this.step, {
    this.methods = const {},
    this.method = SignInMethod.email,
    this.destination = '',
    this.profile,
    this.challenge = '',
    this.consent = false,
    this.busy = false,
    this.issue,
    this.remaining = 0,
  });

  /// Active screen.
  final AccountStep step;

  /// Methods enabled on the server.
  final Set<SignInMethod> methods;

  /// Selected verification channel.
  final SignInMethod method;

  /// Destination of the current request.
  final String destination;

  /// Current profile, retained while linking another method.
  final AccountProfile? profile;

  /// Opaque verification or registration handle.
  final String challenge;

  /// Consent for the current phone number.
  final bool consent;

  /// Request in progress.
  final bool busy;

  /// Feedback for the current action.
  final AccountIssue? issue;

  /// Seconds before another code may be requested.
  final int remaining;

  /// Whether the current flow is adding a method to an existing session.
  bool get linking => profile != null;

  /// Whether to show the phone form.
  bool get telegram => method == SignInMethod.telegram;

  /// The other sign-in method.
  SignInMethod get other =>
      telegram ? SignInMethod.email : SignInMethod.telegram;

  /// An available method missing from this profile.
  SignInMethod? get canLink {
    if (profile?.email == null && methods.contains(SignInMethod.email)) {
      return SignInMethod.email;
    }
    if (profile?.telegram == null && methods.contains(SignInMethod.telegram)) {
      return SignInMethod.telegram;
    }
    return null;
  }

  /// Heading for the address or number form.
  String get entryHeading => linking
      ? (telegram ? t.identity.linkTelegram : t.identity.linkEmail)
      : methods.length > 1
      ? t.identity.method
      : telegram
      ? t.identity.useTelegram
      : t.identity.entry;

  /// The destination as shown on the verification form.
  String get sentLabel => telegram
      ? t.identity.telegramSent(
          phone: '•••• ${destination.substring(destination.length - 4)}',
        )
      : t.identity.sent(email: destination);

  IdentityState _update({
    AccountStep? step,
    String? destination,
    String? challenge,
    bool? consent,
    bool busy = false,
    AccountIssue? issue,
    int? remaining,
  }) => IdentityState(
    step ?? this.step,
    methods: methods,
    profile: profile,
    method: method,
    destination: destination ?? this.destination,
    challenge: challenge ?? this.challenge,
    consent: consent ?? this.consent,
    busy: busy,
    issue: issue,
    remaining: remaining ?? this.remaining,
  );
}

/// Coordinates guest sign-in, explicit registration and authenticated linking.
final class IdentityCubit extends Cubit<IdentityState> {
  /// Checks the account service when its page is first opened.
  IdentityCubit(this._access)
    : super(
        IdentityState(
          _access == null ? AccountStep.unconfigured : AccountStep.loading,
        ),
      ) {
    if (_access != null) unawaited(restore());
  }
  final AccountAccess? _access;
  Timer? _timer;
  DateTime? _resendAt;

  IdentityState _home(
    Set<SignInMethod> methods,
    AccountProfile? profile, {
    AccountIssue? issue,
  }) => IdentityState(
    profile == null ? AccountStep.entry : AccountStep.profile,
    methods: methods,
    profile: profile,
    method: methods.contains(SignInMethod.email)
        ? SignInMethod.email
        : SignInMethod.telegram,
    issue: issue,
  );

  Future<void> _run(
    Future<IdentityState> Function(AccountAccess) action,
  ) async {
    final api = _access;
    if (isClosed || state.busy || api == null) return;
    final prior = state;
    emit(prior._update(busy: true));
    try {
      final next = await action(api);
      if (!isClosed) emit(next);
    } on Object catch (error) {
      if (isClosed) return;
      final issue = error is AccountIssue ? error : AccountIssue.unavailable;
      if (issue == AccountIssue.expiredSession) {
        emit(_home(prior.methods, null, issue: issue));
      } else if (prior.step == AccountStep.registration &&
          issue == AccountIssue.code) {
        emit(
          IdentityState(
            AccountStep.entry,
            methods: prior.methods,
            method: prior.method,
            destination: prior.destination,
            issue: issue,
          ),
        );
      } else {
        final step = switch ((prior.step, issue)) {
          (AccountStep.loading || AccountStep.retry, _) => AccountStep.retry,
          (_, AccountIssue.delivery || AccountIssue.occupied) =>
            AccountStep.problem,
          _ => prior.step,
        };
        emit(prior._update(step: step, issue: issue));
      }
    }
    if (!isClosed) _scheduleResend();
  }

  void _scheduleResend() {
    _timer?.cancel();
    if (state.step != AccountStep.code || _resendAt == null) return;
    void tick() {
      final ms = _resendAt!.difference(DateTime.now()).inMilliseconds;
      final seconds = ms <= 0 ? 0 : (ms + 999) ~/ 1000;
      if (!state.busy && state.remaining != seconds) {
        emit(state._update(remaining: seconds, issue: state.issue));
      }
      if (seconds == 0) _timer?.cancel();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    tick();
  }

  /// Loads capabilities and resumes the device's session.
  Future<void> restore() => _run((api) async {
    final methods = await api.methods();
    if (methods.isEmpty) return const IdentityState(AccountStep.unconfigured);
    return _home(methods, await api.session());
  });

  /// Opens a channel or edits the current destination.
  void entry(SignInMethod method) {
    if (state.busy || !state.methods.contains(method)) return;
    _timer?.cancel();
    emit(
      IdentityState(
        AccountStep.entry,
        methods: state.methods,
        method: method,
        profile: state.profile,
        destination: method == state.method && state.step != AccountStep.profile
            ? state.destination
            : '',
      ),
    );
  }

  /// Returns to the signed-in profile or the guest form.
  void cancel() {
    if (state.busy) return;
    _timer?.cancel();
    emit(_home(state.methods, state.profile));
  }

  /// Records consent for the exact number in the field.
  void allowPhone(String number, {required bool allowed}) {
    if (state.busy || !state.telegram || state.step != AccountStep.entry) {
      return;
    }
    emit(state._update(destination: number, consent: allowed));
  }

  /// Sends the challenge. Editing a number invalidates its previous consent.
  Future<void> request(String value) async {
    if (state.step != AccountStep.entry && state.step != AccountStep.code) {
      return;
    }
    if (state.step == AccountStep.code &&
        (state.remaining > 0 || value != state.destination)) {
      return;
    }
    await _run((api) async {
      var destination = value.trim();
      if (state.telegram) {
        destination = destination.replaceAll(RegExp(r'[\s()-]'), '');
        if (!RegExp(r'^\+[1-9][0-9]{6,14}$').hasMatch(destination)) {
          throw AccountIssue.phone;
        }
        if (!state.consent || value != state.destination) {
          throw AccountIssue.consent;
        }
      } else if (destination.length > 254 ||
          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(destination)) {
        throw AccountIssue.email;
      }
      final id = await api.request(
        state.method,
        destination,
        LocaleSettings.currentLocale.languageCode,
        link: state.linking,
        consent: state.consent,
      );
      _resendAt = DateTime.now().add(const Duration(minutes: 1));
      return state._update(
        step: AccountStep.code,
        destination: destination,
        challenge: id,
        remaining: 60,
      );
    });
  }

  /// Verifies the selected method.
  Future<void> verify(String value) async {
    if (state.step != AccountStep.code) return;
    await _run((api) async {
      final code = value.trim();
      if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) throw AccountIssue.code;
      final result = await api.verify(
        state.challenge,
        code,
        link: state.linking,
      );
      return switch (result) {
        RegistrationProof(:final value) => state._update(
          step: AccountStep.registration,
          challenge: value,
        ),
        AccountProfile() => _home(state.methods, result),
      };
    });
  }

  /// Completes explicit phone registration.
  Future<void> register() async {
    if (state.step != AccountStep.registration) return;
    await _run(
      (api) async => _home(state.methods, await api.register(state.challenge)),
    );
  }

  /// Opens or closes transfer instructions.
  void showCopy({required bool open}) {
    if (state.busy || state.profile == null) return;
    emit(state._update(step: open ? AccountStep.copy : AccountStep.profile));
  }

  /// Revokes only this device's session.
  Future<void> logout() => _run((api) async {
    await api.logout();
    return _home(state.methods, null);
  });

  @override
  Future<void> close() {
    _timer?.cancel();
    _access?.close();
    return super.close();
  }
}

/// Localized feedback on both hosts.
String accountIssueLabel(AccountIssue issue) => switch (issue) {
  AccountIssue.email => t.identity.badEmail,
  AccountIssue.phone => t.identity.badPhone,
  AccountIssue.consent => t.identity.needConsent,
  AccountIssue.code => t.identity.badCode,
  AccountIssue.limited => t.identity.limited,
  AccountIssue.cookies => t.identity.cookies,
  AccountIssue.delivery => t.identity.delivery,
  AccountIssue.occupied => t.identity.occupied,
  AccountIssue.expiredSession => t.identity.expiredSession,
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
