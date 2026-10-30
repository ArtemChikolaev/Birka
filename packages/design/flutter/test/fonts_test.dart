import 'dart:convert';

import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every key with a short text and remembers the keys.
final class _FakeBundle extends CachingAssetBundle {
  final keys = <String>[];

  @override
  Future<ByteData> load(String key) async {
    keys.add(key);
    return ByteData.sublistView(utf8.encode('License from $key'));
  }
}

void main() {
  test('registers the license of every bundled font', () async {
    LicenseRegistry.reset();
    final bundle = _FakeBundle();

    registerFontLicenses(bundle: bundle);
    final licenses = await LicenseRegistry.licenses.toList();

    expect(licenses.map((license) => license.packages), [
      ['Inter'],
      ['Manrope'],
    ]);
    expect(bundle.keys, [
      'packages/design_flutter/fonts/Inter-OFL.txt',
      'packages/design_flutter/fonts/Manrope-OFL.txt',
    ]);
  });
}
