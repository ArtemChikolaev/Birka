/// Failures the account screens can act on.
enum AccountIssue implements Exception {
  /// The service could not be reached.
  unavailable,

  /// The address is malformed.
  email,

  /// The phone number is malformed.
  phone,

  /// The user must agree to phone-number delivery.
  consent,

  /// The delivery provider could not accept the request.
  delivery,

  /// The method already belongs to an account.
  occupied,

  /// The session used to link a method has expired.
  expiredSession,

  /// The code is invalid or expired.
  code,

  /// The service has limited requests.
  limited,

  /// The browser did not retain its session.
  cookies,
}

/// A verified sign-in identifier.
enum SignInMethod {
  /// Mailbox verification.
  email,

  /// Phone verification through Telegram Gateway.
  telegram,
}

/// The outcome of verifying one challenge.
sealed class AccountVerification {
  const AccountVerification();
}

/// Verified methods for one identity. The service masks the stored number.
final class AccountProfile extends AccountVerification {
  /// Creates a profile with its verified identifiers.
  const AccountProfile({this.email, this.telegram});

  /// Verified mailbox.
  final String? email;

  /// Masked Telegram number.
  final String? telegram;
}

/// A verified, unclaimed phone number, pending explicit account creation.
final class RegistrationProof extends AccountVerification {
  /// Creates a one-time proof.
  const RegistrationProof(this.value);

  /// Opaque short-lived proof, held only in memory.
  final String value;
}

/// Access to an identity, independent of the local ledger.
abstract interface class AccountAccess {
  /// Methods available on this server.
  Future<Set<SignInMethod>> methods();

  /// Reads the active session, or null for a guest.
  Future<AccountProfile?> session();

  /// Sends a sign-in or linking code to an explicitly selected destination.
  Future<String> request(
    SignInMethod method,
    String destination,
    String language, {
    required bool link,
    required bool consent,
  });

  /// Consumes a code, preserving the current session when linking.
  Future<AccountVerification> verify(
    String challenge,
    String code, {
    required bool link,
  });

  /// Creates an account for a verified phone number.
  Future<AccountProfile> register(String proof);

  /// Revokes this device's session.
  Future<void> logout();

  /// Releases the network client.
  void close();
}

/// Private native storage for an opaque session token.
abstract interface class SessionVault {
  /// Reads this service's token.
  Future<String?> read();

  /// Replaces the token, or removes it when null.
  Future<void> write(String? token);
}
