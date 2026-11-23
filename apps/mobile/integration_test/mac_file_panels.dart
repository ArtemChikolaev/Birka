import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Supplies the paths normally returned by the macOS panels. The registered
/// file picker and Birka still write and read the files on disk.
void useMacFilePanels(
  WidgetTester tester, {
  required File Function() open,
  File Function(String name)? save,
}) {
  expect(Platform.isMacOS, isTrue, reason: 'This journey uses macOS panels');
  const panel = MethodChannel('miguelruivo.flutter.plugins.filepicker');
  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockMethodCallHandler(panel, (call) async {
      if (call.method == 'any') {
        final file = open();
        return [
          {'path': file.path, 'size': await file.length()},
        ];
      }
      if (call.method == 'save' && save != null) {
        final arguments = call.arguments as Map<Object?, Object?>;
        return save(arguments['fileName']! as String).path;
      }
      throw UnsupportedError('Unexpected file picker method ${call.method}');
    });
  addTearDown(() => messenger.setMockMethodCallHandler(panel, null));
}
