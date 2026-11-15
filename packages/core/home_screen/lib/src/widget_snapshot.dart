import 'dart:convert';

import 'package:meta/meta.dart';

/// What the widgets show of a day (ADR 0031).
enum WidgetDayKind {
  /// What can still be spent today, out of the share of the day.
  plan,

  /// Today took more than its share.
  over,

  /// No salary to count until: what today took.
  spent,
}

/// The figures of one day as the widgets of the home screen draw them, with
/// the words already in the language of the app and the amounts already
/// written, or hidden (ADR 0031).
@immutable
final class WidgetDay {
  /// Creates the figures of [day].
  const WidgetDay({
    required this.day,
    required this.kind,
    required this.label,
    required this.labelShort,
    required this.figure,
    required this.value,
    required this.of,
    required this.ofShort,
    required this.spent,
    required this.spentShort,
    required this.share,
  });

  /// The day, as `yyyy-mm-dd`.
  final String day;

  /// What the day shows.
  final WidgetDayKind kind;

  /// What the figure is, such as «Можно тратить сегодня».
  final String label;

  /// [label] for a small widget, such as «Можно сегодня».
  final String labelShort;

  /// The figure, such as «1 124 ₽», or dots when the amounts are hidden.
  final String figure;

  /// The figure as a number, which the widget rolls to, or `null` when the
  /// amounts are hidden.
  final double? value;

  /// The line under the figure, such as «из 1 744 ₽ на день».
  final String of;

  /// [of] for a small widget, such as «из 1 744 ₽».
  final String ofShort;

  /// The last line, such as «Потратили 620 ₽», or empty.
  final String spent;

  /// [spent] for a small widget, such as «потратили 620 ₽», or empty.
  final String spentShort;

  /// The part of the share of the day that is spent, from 0 to 1.
  final double share;

  /// The day with the digits of its amounts hidden.
  WidgetDay masked() => WidgetDay(
    day: day,
    kind: kind,
    label: label,
    labelShort: labelShort,
    figure: maskAmounts(figure),
    value: null,
    of: maskAmounts(of),
    ofShort: maskAmounts(ofShort),
    spent: maskAmounts(spent),
    spentShort: maskAmounts(spentShort),
    share: share,
  );

  /// The figures as the widgets read them.
  Map<String, Object?> toJson() => {
    'day': day,
    'kind': kind.name,
    'label': label,
    'labelShort': labelShort,
    'figure': figure,
    'value': value,
    'of': of,
    'ofShort': ofShort,
    'spent': spent,
    'spentShort': spentShort,
    'share': share,
  };
}

/// What the widgets of the home screen show: the figures of today and of
/// tomorrow, as if nothing more is spent today, so that they turn to the
/// next day at midnight on their own (ADR 0031). A day that is not there
/// asks the person to open Birka.
@immutable
final class WidgetSnapshot {
  /// Creates the figures of [days], whose amounts are shown with [sums].
  const WidgetSnapshot({required this.days, required this.sums});

  /// The version of [encode] that the widgets read.
  static const version = 1;

  /// The days, the earliest first.
  final List<WidgetDay> days;

  /// Whether the amounts are shown, or hidden behind dots.
  final bool sums;

  /// The figures with the digits of their amounts hidden, as the widgets get
  /// them while «Суммы в виджетах» is off.
  WidgetSnapshot masked() => WidgetSnapshot(
    days: [for (final day in days) day.masked()],
    sums: false,
  );

  /// The figures as the widgets read them.
  Map<String, Object?> toJson() => {
    'v': version,
    'sums': sums,
    'days': [for (final day in days) day.toJson()],
  };

  /// [toJson] as text, which the host hands to the widgets.
  String encode() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is WidgetSnapshot && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;
}

/// [text] with the digits of its amounts hidden, as the app hides them: the
/// sign and the currency stay, and the length of the number goes.
String maskAmounts(String text) => text.replaceAll(_digits, '•••');

final _digits = RegExp(r'\d(?:[\d\s.,]*\d)?[kMB]?');
