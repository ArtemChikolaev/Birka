import 'dart:typed_data';

/// A file that a person chose.
abstract interface class ChosenFile {
  /// Its name, such as `birka-2026-10-28.birka`.
  String get name;

  /// Its size in bytes, or `null` when it is known only once it is read.
  Future<int?> length();

  /// What it holds.
  Future<Uint8List> read();
}

/// The windows of the system that save and open files, which each host has
/// its own way to show (ADR 0016).
abstract interface class BackupFiles {
  /// Lets the person save [bytes] as [name] wherever they choose. [type] is
  /// the media type of the file. Returns whether they saved it.
  Future<bool> save({
    required String name,
    required String type,
    required Uint8List bytes,
  });

  /// Lets the person choose a file. Returns `null` when they chose none.
  Future<ChosenFile?> open();
}
