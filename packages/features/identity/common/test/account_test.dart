import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:identity_common/identity_common.dart';
import 'package:test/test.dart';

class _Vault implements SessionVault {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String? value) async => token = value;
}

void main() {
  final endpoint = Uri.parse('https://example.test/auth/');
  test('accepts a secure service root and local development', () {
    for (final raw in [
      '',
      'http://example.test',
      'https://user:pass@example.test',
      'https://example.test/?key=x',
    ]) {
      expect(accountEndpoint(raw), isNull);
    }
    expect(accountEndpoint('http://127.0.0.1:8787')?.path, '/');
    expect(accountEndpoint('https://example.test/auth'), endpoint);
  });

  test(
    'native guest, validation, new challenge, verification and logout',
    () async {
      final vault = _Vault();
      var sent = 0;
      final api = AccountApi(
        endpoint,
        MockClient((r) async {
          expect(r.headers['X-Birka-Client'], 'native');
          expect(r.url.path, startsWith('/auth/v1/'));
          switch (r.url.pathSegments.last) {
            case 'code':
              expect(
                (jsonDecode(r.body) as Map)['email'],
                'local@example.test',
              );
              return http.Response(
                jsonEncode({'challenge': 'c${++sent}'}),
                200,
              );
            case 'verify':
              final body = jsonDecode(r.body) as Map;
              expect(body['challenge'], 'c2');
              if (body['code'] != '123456') return http.Response('', 401);
              return http.Response(
                '{"email":"local@example.test","token":"device-token"}',
                200,
              );
            case 'session':
            case 'logout':
              expect(r.headers['Authorization'], 'Bearer device-token');
              return r.method == 'GET'
                  ? http.Response('{"email":"local@example.test"}', 200)
                  : http.Response('', 204);
          }
          fail('unknown route');
        }),
        vault: vault,
      );
      final cubit = IdentityCubit(api);
      addTearDown(cubit.close);
      await cubit.stream.firstWhere((s) => s.step == AccountStep.email);
      await cubit.request('invalid');
      expect(cubit.state.issue, AccountIssue.email);
      expect(sent, 0);
      await cubit.request(' local@example.test ');
      await cubit.request(cubit.state.email);
      expect(cubit.state.challenge, 'c2');
      await cubit.verify('000000');
      expect(cubit.state.issue, AccountIssue.code);
      await cubit.verify('123456');
      expect(cubit.state.step, AccountStep.profile);
      expect(await api.session(), 'local@example.test');
      await cubit.logout();
      expect(cubit.state.step, AccountStep.email);
      expect(vault.token, isNull);
    },
  );

  test(
    'browser confirms receipt of its session cookie after verification',
    () async {
      final api = AccountApi(
        endpoint,
        MockClient((r) async {
          expect(r.headers.containsKey('Authorization'), isFalse);
          expect(r.headers['X-Birka-Client'], 'web');
          return r.method == 'POST'
              ? http.Response('{"email":"a@example.test"}', 200)
              : http.Response('', 401);
        }),
      );
      addTearDown(api.close);
      await expectLater(
        api.verify('challenge', '012345'),
        throwsA(AccountIssue.cookies),
      );
    },
  );

  test('expired native session clears private storage', () async {
    final vault = _Vault()..token = 'expired';
    final api = AccountApi(
      endpoint,
      MockClient((r) async => http.Response('', 401)),
      vault: vault,
    );
    addTearDown(api.close);
    expect(await api.session(), isNull);
    expect(vault.token, isNull);
  });

  test('a failed restore can retry without two requests in flight', () async {
    final gate = Completer<http.Response>();
    var requests = 0;
    final cubit = IdentityCubit(
      AccountApi(
        endpoint,
        MockClient((r) {
          if (++requests == 1) return gate.future;
          return Future.value(http.Response('', 401));
        }),
      ),
    );
    addTearDown(cubit.close);
    await cubit.restore();
    gate.complete(http.Response('', 503));
    await cubit.stream.firstWhere((s) => s.step == AccountStep.retry);
    await cubit.restore();
    expect(cubit.state.step, AccountStep.email);
    expect(requests, 2);
  });
}
