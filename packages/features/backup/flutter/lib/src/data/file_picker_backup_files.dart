import 'dart:typed_data';

import 'package:backup_common/backup_common.dart';
import 'package:file_picker/file_picker.dart';

/// The windows of the system that save and open files on phones: the Files
/// app on iOS and the documents of Android (ADR 0016).
final class FilePickerBackupFiles implements BackupFiles {
  /// Creates the windows.
  const FilePickerBackupFiles();

  @override
  Future<bool> save({
    required String name,
    required String type,
    required Uint8List bytes,
  }) async {
    final saved = await FilePicker.saveFile(
      fileName: name,
      bytes: bytes,
      mimeType: type,
    );
    return saved != null;
  }

  @override
  Future<ChosenFile?> open() async {
    final file = await FilePicker.pickFile();
    return file == null ? null : _PickedFile(file);
  }
}

final class _PickedFile implements ChosenFile {
  const _PickedFile(this._file);

  final PlatformFile _file;

  @override
  String get name => _file.name;

  /// What the picker knows without reading the file, which may be nothing.
  @override
  Future<int?> length() async => _file.lengthSync();

  @override
  Future<Uint8List> read() => _file.readAsBytes();
}
