import 'package:l10n/src/generated/strings.g.dart';

/// A day for people: `30 октября` or `October 30`, with the year when it is
/// not [thisYear]. The day is [day] of [month] of [year] on a calendar.
String dateLabel({
  required int year,
  required int month,
  required int day,
  required int thisYear,
}) {
  final date = t.transactions.dayOfMonth(
    day: day,
    month: t.transactions.months[month - 1],
  );
  return year == thisYear ? date : '$date $year';
}

/// The time of [moment] on the clock of this device: `08:42`.
String timeLabel(DateTime moment) {
  final local = moment.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
