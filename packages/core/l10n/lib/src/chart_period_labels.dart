import 'package:l10n/src/generated/strings.g.dart';

/// The name of a period of a chart on its switch. [period] is its name: `week`,
/// `month` or `year`.
String chartPeriodLabel(String period) => switch (period) {
  'week' => t.overview.week,
  'month' => t.overview.month,
  _ => t.overview.year,
};

/// What a change over a period covers: `за неделю` or `за октябрь`. [period] is
/// its name, and [month] is the number of the month of today.
String chartPeriodCaption(String period, {required int month}) =>
    switch (period) {
      'week' => t.overview.inWeek,
      'month' => t.overview.changeIn[month - 1],
      _ => t.overview.inYear,
    };
