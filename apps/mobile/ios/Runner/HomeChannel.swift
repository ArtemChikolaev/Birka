import AppIntents
import Flutter
import UIKit
import WidgetKit

/// The channel `birka/widgets` (ADR 0031). Dart hands the figures of the day
/// over as JSON, which goes to the App Group that the widgets read. What
/// opens Birka from outside — a widget, an action of the icon, the control,
/// Siri — waits here until Dart asks for it, and the later ones go to Dart as
/// they come.
final class HomeChannel {
  /// The App Group that the app and its widgets share.
  static let group = "group.io.github.artemchikolaev.birka"

  /// Where the figures live in the App Group.
  static let key = "snapshot"

  private let channel: FlutterMethodChannel
  private var pending: String?
  private var listening = false

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "birka/widgets", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result)
    }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "show":
      if let json = call.arguments as? String {
        UserDefaults(suiteName: Self.group)?.set(json, forKey: Self.key)
        WidgetCenter.shared.reloadAllTimelines()
      }
      result(nil)
    case "canPin", "pin":
      // A widget comes to the home screen of iOS from its gallery alone.
      result(false)
    case "takeAction":
      listening = true
      result(pending)
      pending = nil
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Opens [action] in the app: now, if Dart listens, or once it asks.
  func deliver(_ action: String) {
    if listening {
      channel.invokeMethod("open", arguments: action)
    } else {
      pending = action
    }
  }
}

/// «Записать трату» for Siri, the app Shortcuts and Spotlight (ADR 0031).
@available(iOS 18.0, *)
struct BirkaShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: RecordExpenseIntent(),
      phrases: ["Record an expense in \(.applicationName)"],
      shortTitle: "shortcut.record",
      systemImageName: "plus"
    )
  }
}
