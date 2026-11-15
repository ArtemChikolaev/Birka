import AppIntents
import Foundation

// What opens Birka from outside its window (ADR 0031). A tap on a widget
// comes as `birka://<action>`; a button of a widget, the control and Siri run
// one of these intents, which open the app and run there. Either way the app
// passes the action to Dart over the channel `birka/widgets`. Each intent
// knows its action: a parameter would not survive the way from the widget to
// the app.

/// What the app does with the action of an intent. The widgets leave it
/// alone.
@available(iOS 18.0, *)
enum BirkaIntents {
  @MainActor static var handler: ((String) -> Void)?
}

/// A new expense: the buttons «+» and «Расход», the control and Siri.
@available(iOS 18.0, *)
struct RecordExpenseIntent: AppIntent {
  static let title: LocalizedStringResource = "intent.expense"

  static let openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    BirkaIntents.handler?("expense")
    return .result()
  }
}

/// A new income: the button «Доход».
@available(iOS 18.0, *)
struct RecordIncomeIntent: AppIntent {
  static let title: LocalizedStringResource = "intent.income"

  static let openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    BirkaIntents.handler?("income")
    return .result()
  }
}
