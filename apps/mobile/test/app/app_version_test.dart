import 'dart:io';

import 'package:birka_mobile/app/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the app says the version that its pubspec says', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('\nversion: $appVersion+'));
  });
}
