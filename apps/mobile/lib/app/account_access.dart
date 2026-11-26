import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:identity_common/identity_common.dart';

/// Opens the session store and transport only when the account page is visited.
IdentityCubit createNativeAccount() {
  final endpoint = accountEndpoint();
  return IdentityCubit(
    endpoint == null
        ? null
        : AccountApi(endpoint, http.Client(), vault: _AccountVault(endpoint)),
  );
}

final class _AccountVault implements SessionVault {
  _AccountVault(Uri endpoint)
    : key = 'birka.account.${Uri.encodeComponent(endpoint.toString())}';
  final String key;
  // The development macOS app is ad-hoc signed. Its login keychain works
  // without a provisioning profile or a shared keychain access group.
  static const _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  @override
  Future<String?> read() => _storage.read(key: key);
  @override
  Future<void> write(String? token) => token == null
      ? _storage.delete(key: key)
      : _storage.write(key: key, value: token);
}
