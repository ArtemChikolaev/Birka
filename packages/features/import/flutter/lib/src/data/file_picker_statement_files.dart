import 'package:file_picker/file_picker.dart';
import 'package:import_common/import_common.dart';

/// The window of the system that opens a statement on phones: the Files app
/// on iOS and the documents of Android, as for a copy of the ledger
/// (ADR 0016).
final class FilePickerStatementFiles implements StatementFiles {
  /// Creates the window.
  const FilePickerStatementFiles();

  @override
  Future<ChosenStatement?> choose() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    return ChosenStatement(file.name, await file.readAsBytes());
  }
}
