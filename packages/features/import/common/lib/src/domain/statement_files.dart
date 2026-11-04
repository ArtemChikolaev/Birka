import 'dart:typed_data';

import 'package:meta/meta.dart';

/// A file of a statement that a person chose.
@immutable
final class ChosenStatement {
  /// Creates the file.
  const ChosenStatement(this.name, this.bytes);

  /// Its name, such as `alfa-2026-10.xlsx`.
  final String name;

  /// What it holds.
  final Uint8List bytes;
}

/// The window of the system that opens a statement, which each host has its
/// own way to show.
// ignore: one_member_abstracts, a port that each host implements.
abstract interface class StatementFiles {
  /// Lets the person choose the file of a statement: CSV, Excel or PDF.
  /// Returns `null` when they chose none.
  Future<ChosenStatement?> choose();
}
