import 'package:drift/wasm.dart';

/// The worker that runs SQLite. The Jaspr build compiles it next to the pages
/// (ADR 0009).
void main() => WasmDatabase.workerMainForOpen();
