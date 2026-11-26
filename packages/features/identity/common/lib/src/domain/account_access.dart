/// Failures the account screens can act on.
enum AccountIssue implements Exception {
  /// The service could not be reached.
  unavailable,

  /// The address is malformed.
  email,

  /// The code is invalid or expired.
  code,

  /// The service has limited requests.
  limited,

  /// The browser did not retain its session.
  cookies,
}

/// Access to an identity, independent of the local ledger.
abstract interface class AccountAccess {
  /// Reads the active session, or null for a guest.
  Future<String?> session();

  /// Sends a new code and returns its challenge handle.
  Future<String> request(String email, String language);

  /// Consumes a code and returns the verified address.
  Future<String> verify(String challenge, String code);

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
