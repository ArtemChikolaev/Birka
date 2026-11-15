import Foundation

/// The figures of one day, as the app writes them (ADR 0031, version 1 of
/// the snapshot): the words are in the language of the app, and the amounts
/// are written out or hidden behind dots.
struct WidgetDay: Decodable, Hashable {
  let day: String
  let kind: String
  let label: String
  let labelShort: String
  let figure: String
  let value: Double?
  let of: String
  let ofShort: String
  let spent: String
  let spentShort: String
  let share: Double

  /// Whether the day shows what today took, with no salary to count until.
  var spentOnly: Bool { kind == "spent" }

  /// Whether today took more than its share.
  var over: Bool { kind == "over" }

  /// The key of [date] in the calendar of the phone, as `yyyy-mm-dd`.
  static func key(of date: Date) -> String {
    let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
  }

  /// The figures of the boards, for the gallery of the widgets.
  static var sample: WidgetDay {
    WidgetDay(
      day: key(of: .now),
      kind: "plan",
      label: String(localized: "sample.label"),
      labelShort: String(localized: "sample.labelShort"),
      figure: String(localized: "sample.figure"),
      value: 1124,
      of: String(localized: "sample.of"),
      ofShort: String(localized: "sample.ofShort"),
      spent: String(localized: "sample.spent"),
      spentShort: String(localized: "sample.spentShort"),
      share: 0.36
    )
  }
}

/// What the app handed over last: today and tomorrow.
struct WidgetSnapshot: Decodable {
  let v: Int
  let sums: Bool
  let days: [WidgetDay]

  /// The snapshot in the App Group, if the app has written one this widget
  /// can read.
  static func read() -> WidgetSnapshot? {
    guard
      let json = UserDefaults(suiteName: "group.io.github.artemchikolaev.birka")?.string(forKey: "snapshot"),
      let data = json.data(using: .utf8),
      let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data),
      snapshot.v == 1
    else { return nil }
    return snapshot
  }
}
