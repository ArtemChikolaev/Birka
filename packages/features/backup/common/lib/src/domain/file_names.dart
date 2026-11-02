import 'package:ledger/ledger.dart';

/// The media type of a copy. Android keeps a name with any extension as it is
/// for this type, and adds `.json` to it for JSON.
const copyFileType = 'application/octet-stream';

/// The media type of a table of operations.
const operationsFileType = 'text/csv';

/// The largest file that can be a copy: far more than a ledger of many years
/// takes, and far less than a video chosen by mistake.
const int largestCopy = 64 * 1024 * 1024;

/// The name of a copy made at [moment]: `birka-2026-11-02.birka`, with the day
/// on the calendar of this device.
String copyFileName(DateTime moment) => 'birka-${_day(moment)}.birka';

/// The name of a table of operations made at [moment]:
/// `birka-operations-2026-11-02.csv`.
String operationsFileName(DateTime moment) =>
    'birka-operations-${_day(moment)}.csv';

String _day(DateTime moment) => CivilDate.of(moment.toLocal()).toString();
