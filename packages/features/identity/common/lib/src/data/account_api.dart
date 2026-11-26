import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:identity_common/src/domain/account_access.dart';

/// The service root. Local development also accepts HTTP on loopback.
Uri? accountEndpoint([
  String raw = const String.fromEnvironment('BIRKA_AUTH_URL'),
]) {
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }
  if (uri.scheme != 'https' &&
      !(uri.scheme == 'http' &&
          const {'localhost', '127.0.0.1', '::1'}.contains(uri.host))) {
    return null;
  }
  return uri.replace(path: uri.path.endsWith('/') ? uri.path : '${uri.path}/');
}

/// Both clients use the same protocol. The browser receives an HttpOnly cookie.
final class AccountApi implements AccountAccess {
  /// A browser [client] includes credentials. Native clients supply a [vault].
  AccountApi(this.endpoint, this.client, {this.vault});

  /// Configured service root.
  final Uri endpoint;

  /// HTTP transport owned by the account screen.
  final http.Client client;

  /// Native session storage, absent for the browser.
  final SessionVault? vault;

  Future<http.Response> _call(
    String method,
    String path, {
    Map<String, Object>? data,
    String? token,
  }) async {
    final req = http.Request(method, endpoint.resolve('v1/$path'))
      ..followRedirects = false
      ..headers['X-Birka-Client'] = vault == null ? 'web' : 'native';
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (data != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(data);
    }
    return client
        .send(req)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 25));
  }

  Map<String, dynamic> _data(http.Response r) {
    if (r.statusCode == 429) throw AccountIssue.limited;
    if (r.statusCode != 200) throw AccountIssue.unavailable;
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  AccountProfile _profile(Map<String, dynamic> data) {
    final email = data['email'] as String?;
    final telegram = data['telegram'] as String?;
    if (email == null && telegram == null) throw AccountIssue.unavailable;
    return AccountProfile(email: email, telegram: telegram);
  }

  @override
  Future<Set<SignInMethod>> methods() async {
    final r = await _call('GET', 'methods');
    if (r.statusCode == 404) return {SignInMethod.email};
    final data = _data(r);
    return {
      for (final method in SignInMethod.values)
        if (data[method.name] == true) method,
    };
  }

  @override
  Future<AccountProfile?> session() async {
    final token = await vault?.read();
    if (vault != null && token == null) return null;
    final r = await _call('GET', 'session', token: token);
    if (r.statusCode == 401) {
      await vault?.write(null);
      return null;
    }
    return _profile(_data(r));
  }

  @override
  Future<String> request(
    SignInMethod method,
    String destination,
    String language, {
    required bool link,
    required bool consent,
  }) async {
    final telegram = method == SignInMethod.telegram;
    final r = await _call(
      'POST',
      'code',
      data: {
        if (telegram) 'phone': destination else 'email': destination,
        'language': language,
        if (telegram) 'consent': consent,
        if (link) 'link': true,
      },
      token: link ? await vault?.read() : null,
    );
    if (r.statusCode == 400) {
      throw telegram ? AccountIssue.phone : AccountIssue.email;
    }
    if (r.statusCode == 401) throw AccountIssue.expiredSession;
    if (r.statusCode == 409) throw AccountIssue.occupied;
    if (r.statusCode == 502) throw AccountIssue.delivery;
    return _data(r)['challenge'] as String;
  }

  @override
  Future<AccountVerification> verify(
    String challenge,
    String code, {
    required bool link,
  }) async {
    final r = await _call(
      'POST',
      'verify',
      data: {'challenge': challenge, 'code': code},
      token: link ? await vault?.read() : null,
    );
    if (r.statusCode == 401) {
      if (link &&
          r.body.isNotEmpty &&
          (jsonDecode(r.body) as Map)['error'] == 'session') {
        throw AccountIssue.expiredSession;
      }
      throw AccountIssue.code;
    }
    if (r.statusCode == 409) throw AccountIssue.occupied;
    final data = _data(r);
    if (data['registration'] case final String proof) {
      return RegistrationProof(proof);
    }
    return link ? _profile(data) : await _saveSession(data);
  }

  @override
  Future<AccountProfile> register(String proof) async {
    final r = await _call('POST', 'register', data: {'registration': proof});
    if (r.statusCode == 401) throw AccountIssue.code;
    return _saveSession(_data(r));
  }

  Future<AccountProfile> _saveSession(Map<String, dynamic> data) async {
    final profile = _profile(data);
    final store = vault;
    if (store == null) return await session() ?? (throw AccountIssue.cookies);
    final token = data['token'] as String;
    try {
      await store.write(token);
      if (await store.read() != token) throw AccountIssue.unavailable;
    } on Object {
      await _call('POST', 'logout', token: token);
      rethrow;
    }
    return profile;
  }

  @override
  Future<void> logout() async {
    final token = await vault?.read();
    final r = await _call('POST', 'logout', token: token);
    if (r.statusCode != 204 && r.statusCode != 401) {
      throw AccountIssue.unavailable;
    }
    await vault?.write(null);
  }

  @override
  void close() => client.close();
}
