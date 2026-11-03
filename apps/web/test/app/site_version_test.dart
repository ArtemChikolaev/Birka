import 'dart:io';

import 'package:birka_web/app/site_version.dart';
import 'package:test/test.dart';

void main() {
  test('the site says the version that its pubspec says', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('\nversion: $siteVersion\n'));
  });
}
