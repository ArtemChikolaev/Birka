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
    Map<String, String>? data,
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

  @override
  Future<String?> session() async {
    final token = await vault?.read();
    if (vault != null && token == null) return null;
    final r = await _call('GET', 'session', token: token);
    if (r.statusCode == 401) {
      await vault?.write(null);
      return null;
    }
    return _data(r)['email'] as String;
  }

  @override
  Future<String> request(String email, String language) async {
    final r = await _call(
      'POST',
      'code',
      data: {'email': email, 'language': language},
    );
    if (r.statusCode == 400) throw AccountIssue.email;
    return _data(r)['challenge'] as String;
  }

  @override
  Future<String> verify(String challenge, String code) async {
    final r = await _call(
      'POST',
      'verify',
      data: {'challenge': challenge, 'code': code},
    );
    if (r.statusCode == 401) throw AccountIssue.code;
    final data = _data(r);
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
    return data['email'] as String;
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
