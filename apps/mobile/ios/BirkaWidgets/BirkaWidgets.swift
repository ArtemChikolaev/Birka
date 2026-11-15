import AppIntents
import SwiftUI
import WidgetKit

// The widgets of Birka (ADR 0031): «Сегодня» with what can still be spent
// today, «Запись» with one button and no amounts, the same two on the lock
// screen, and the control «Записать». They read the figures that the app
// hands over and never the ledger.

@main
struct BirkaWidgets: WidgetBundle {
  var body: some Widget {
    TodayWidget()
    RecordWidget()
    RecordControl()
  }
}

// MARK: - The look, after packages/design/tokens

private enum Look {
  static let accent = Color(red: 0x3D / 255, green: 0xDC / 255, blue: 0x97 / 255)
  static let onAccent = Color(red: 0x02 / 255, green: 0x13 / 255, blue: 0x0B / 255)
  static let coral = Color(red: 0xFF / 255, green: 0x8E / 255, blue: 0x7F / 255)
  static let ink = Color(red: 0xF4 / 255, green: 0xF4 / 255, blue: 0xF2 / 255)
  static let muted = Color(red: 0xA3 / 255, green: 0xA3 / 255, blue: 0xA3 / 255)
  static let ground = Color(red: 0x05 / 255, green: 0x07 / 255, blue: 0x06 / 255)
  static let glow = Color(red: 0x24 / 255, green: 0x8A / 255, blue: 0x56 / 255)

  /// The figures, in Manrope as in the app.
  static func figure(_ size: CGFloat) -> Font {
    .custom("Manrope", size: size).weight(.heavy)
  }
}

private struct Ground: View {
  var body: some View {
    ZStack {
      Look.ground
      RadialGradient(
        colors: [Look.glow.opacity(0.34), .clear],
        center: .topLeading, startRadius: 0, endRadius: 220)
      RadialGradient(
        colors: [Look.glow.opacity(0.2), .clear],
        center: .bottomTrailing, startRadius: 0, endRadius: 200)
    }
  }
}

// MARK: - «Сегодня»

struct TodayEntry: TimelineEntry {
  let date: Date
  let day: WidgetDay?
  let words: Words

  /// Where a tap on the widget leads: the overview, or the payday while no
  /// salary is set.
  var url: URL {
    URL(string: day?.spentOnly == true ? "birka://payday" : "birka://overview")!
  }

  /// The figures of [date] in [snapshot]. None asks the person to open
  /// Birka.
  static func at(_ date: Date, in snapshot: WidgetSnapshot?) -> TodayEntry {
    let key = WidgetDay.key(of: date)
    return TodayEntry(
      date: date, day: snapshot?.days.first { $0.day == key },
      words: WidgetSnapshot.words(of: snapshot))
  }
}

struct TodayProvider: TimelineProvider {
  func placeholder(in context: Context) -> TodayEntry {
    TodayEntry(date: .now, day: .sample, words: Words(given: [:]))
  }

  func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
    let entry = TodayEntry.at(.now, in: WidgetSnapshot.read())
    completion(
      context.isPreview && entry.day == nil
        ? TodayEntry(date: .now, day: .sample, words: entry.words) : entry)
  }

  // Today now, and the next days at their midnights, so that the widget turns
  // to them on its own.
  func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
    let snapshot = WidgetSnapshot.read()
    let calendar = Calendar.current
    var entries = [TodayEntry.at(.now, in: snapshot)]
    var midnight = calendar.startOfDay(for: .now)
    for _ in 0..<2 {
      midnight = calendar.date(byAdding: .day, value: 1, to: midnight)!
      entries.append(TodayEntry.at(midnight, in: snapshot))
    }
    completion(Timeline(entries: entries, policy: .after(midnight)))
  }
}

struct TodayWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "BirkaToday", provider: TodayProvider()) { entry in
      TodayView(entry: entry)
    }
    .configurationDisplayName("today.name")
    .description("today.description")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
  }
}

struct TodayView: View {
  @Environment(\.widgetFamily) private var family
  let entry: TodayEntry

  var body: some View {
    switch family {
    case .systemMedium:
      TodayMedium(entry: entry)
        .containerBackground(for: .widget) { Ground() }
    case .accessoryRectangular:
      TodayLock(entry: entry)
        .containerBackground(for: .widget) { Color.clear }
    default:
      TodaySmall(entry: entry)
        .containerBackground(for: .widget) { Ground() }
    }
  }
}

/// The figure of the day: it rolls to a new value, turns coral over the
/// share, and hides on a locked phone.
private struct Figure: View {
  let day: WidgetDay?
  let size: CGFloat

  var body: some View {
    Text(verbatim: day?.figure ?? "—")
      .font(Look.figure(size))
      .foregroundStyle(day?.over == true ? Look.coral : Look.ink)
      .contentTransition(.numericText(value: Double(day?.minor ?? 0)))
      .lineLimit(1)
      .minimumScaleFactor(0.6)
      .privacySensitive()
      .widgetAccentable()
  }
}

/// The part of the share of the day that is spent.
private struct ShareBar: View {
  let day: WidgetDay
  let height: CGFloat

  var body: some View {
    GeometryReader { box in
      ZStack(alignment: .leading) {
        Capsule().fill(Color.white.opacity(0.10))
        Capsule()
          .fill(day.over ? Look.coral : Look.accent)
          .frame(width: box.size.width * min(max(day.share, 0), 1))
          .widgetAccentable()
      }
    }
    .frame(height: height)
    .privacySensitive()
  }
}

private struct Heading: View {
  let text: String
  let size: CGFloat

  var body: some View {
    Text(verbatim: text.uppercased())
      .font(.system(size: size, weight: .bold))
      .tracking(size * 0.06)
      .foregroundStyle(Look.muted)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
  }
}

private struct Line: View {
  let text: String
  let size: CGFloat
  var lines = 1

  var body: some View {
    Text(verbatim: text)
      .font(.system(size: size))
      .foregroundStyle(Look.muted)
      .lineLimit(lines)
      .privacySensitive()
  }
}

private struct PlusCircle: View {
  let size: CGFloat

  var body: some View {
    Image(systemName: "plus")
      .font(.system(size: size * 0.46, weight: .bold))
      .foregroundStyle(Look.onAccent)
      .frame(width: size, height: size)
      .background(Circle().fill(Look.accent))
      .widgetAccentable()
  }
}

private struct Pill: View {
  let symbol: String
  let title: String
  let main: Bool

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: symbol).font(.system(size: 15, weight: .bold))
      Text(verbatim: title).font(.system(size: 15, weight: .bold)).lineLimit(1).minimumScaleFactor(0.8)
    }
    .foregroundStyle(main ? Look.onAccent : Look.ink)
    .frame(maxWidth: .infinity, minHeight: 52)
    .background(Capsule().fill(main ? Look.accent : Color.white.opacity(0.10)))
    .widgetAccentable(main)
  }
}

private struct TodaySmall: View {
  let entry: TodayEntry

  var body: some View {
    let day = entry.day
    VStack(alignment: .leading, spacing: 2) {
      Heading(text: day?.labelShort ?? entry.words("labelShort"), size: 11)
      Figure(day: day, size: 28)
      Line(text: day?.ofShort ?? entry.words("open"), size: 12, lines: 2)
      if let spent = day?.spentShort, !spent.isEmpty {
        Line(text: spent, size: 12)
      }
      Spacer(minLength: 0)
      HStack(alignment: .center, spacing: 10) {
        if let day, !day.spentOnly {
          ShareBar(day: day, height: 5)
        } else {
          Spacer(minLength: 0)
        }
        Button(intent: RecordExpenseIntent()) {
          PlusCircle(size: 40)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: entry.words("newOperation")))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .widgetURL(entry.url)
  }
}

private struct TodayMedium: View {
  let entry: TodayEntry

  var body: some View {
    let day = entry.day
    HStack(alignment: .center, spacing: 14) {
      VStack(alignment: .leading, spacing: 3) {
        Heading(text: day?.label ?? entry.words("label"), size: 12)
        Figure(day: day, size: 32)
        Line(text: day?.of ?? entry.words("open"), size: 13, lines: 2)
        Spacer(minLength: 0)
        if let day, !day.spentOnly {
          ShareBar(day: day, height: 6)
          Line(text: day.spent, size: 13)
            .padding(.top, 2)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      VStack(spacing: 10) {
        Button(intent: RecordExpenseIntent()) {
          Pill(symbol: "minus", title: entry.words("expense"), main: true)
        }
        .buttonStyle(.plain)
        Button(intent: RecordIncomeIntent()) {
          Pill(symbol: "plus", title: entry.words("income"), main: false)
        }
        .buttonStyle(.plain)
      }
      .frame(width: 104)
    }
    .widgetURL(entry.url)
  }
}

/// The lock screen: the amount stays hidden until Face ID.
private struct TodayLock: View {
  let entry: TodayEntry

  var body: some View {
    let day = entry.day
    VStack(alignment: .leading, spacing: 2) {
      Text(verbatim: day?.labelShort ?? entry.words("labelShort"))
        .font(.system(size: 14, weight: .semibold))
        .lineLimit(1)
        .widgetAccentable()
      Text(verbatim: day?.figure ?? "—")
        .font(Look.figure(22))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .contentTransition(.numericText(value: Double(day?.minor ?? 0)))
        .privacySensitive()
      if let day, !day.spentOnly {
        ProgressView(value: min(max(day.share, 0), 1))
          .progressViewStyle(.linear)
          .privacySensitive()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .widgetURL(entry.url)
  }
}

// MARK: - «Запись»

struct RecordEntry: TimelineEntry {
  let date: Date
  let words: Words

  static var now: RecordEntry {
    RecordEntry(date: .now, words: WidgetSnapshot.words(of: WidgetSnapshot.read()))
  }
}

struct RecordProvider: TimelineProvider {
  func placeholder(in context: Context) -> RecordEntry {
    RecordEntry(date: .now, words: Words(given: [:]))
  }

  func getSnapshot(in context: Context, completion: @escaping (RecordEntry) -> Void) {
    completion(.now)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<RecordEntry>) -> Void) {
    completion(Timeline(entries: [.now], policy: .never))
  }
}

struct RecordWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "BirkaRecord", provider: RecordProvider()) { entry in
      RecordView(words: entry.words)
    }
    .configurationDisplayName("record.name")
    .description("record.description")
    .supportedFamilies([.systemSmall, .accessoryCircular])
  }
}

struct RecordView: View {
  @Environment(\.widgetFamily) private var family
  let words: Words

  var body: some View {
    if family == .accessoryCircular {
      ZStack {
        AccessoryWidgetBackground()
        Image(systemName: "plus").font(.system(size: 26, weight: .bold))
      }
      .accessibilityLabel(Text(verbatim: words("newOperation")))
      .widgetURL(URL(string: "birka://expense"))
      .containerBackground(for: .widget) { Color.clear }
    } else {
      VStack(spacing: 12) {
        PlusCircle(size: 64)
        Text(verbatim: words("newOperation"))
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Look.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .widgetURL(URL(string: "birka://expense"))
      .containerBackground(for: .widget) { Ground() }
    }
  }
}

// MARK: - The control «Записать»

/// The button of Control Center, of the lock screen and of the Action button.
struct RecordControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "io.github.artemchikolaev.birka.record") {
      ControlWidgetButton(action: RecordExpenseIntent()) {
        Label("control.title", systemImage: "plus")
      }
    }
    .displayName("control.title")
    .description("control.description")
  }
}
