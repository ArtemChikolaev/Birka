/// What the host needs from the browser. Static mode runs the islands on the
/// VM at build time, so this is a stub there (ADR 0008).
library;

export 'package:birka_web/app/browser_stub.dart'
    if (dart.library.js_interop) 'package:birka_web/app/browser_web.dart';
