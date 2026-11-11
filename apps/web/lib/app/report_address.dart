import 'package:ledger/ledger.dart' show CivilDate;

/// The address of the reports open on [month]: `reports/#2026-10`.
String reportAddress(CivilDate month) =>
    'reports/#${month.year}-${month.month.toString().padLeft(2, '0')}';

/// The month that a fragment of the reports asks for, such as `2026-10`, or
/// `null` for any other fragment.
CivilDate? reportMonthIn(String fragment) {
  final match = _month.firstMatch(fragment);
  if (match == null) return null;
  final month = int.parse(match[2]!);
  if (month < 1 || month > 12) return null;
  return CivilDate(int.parse(match[1]!), month, 1);
}

final _month = RegExp(r'^(\d{4})-(\d{2})$');
