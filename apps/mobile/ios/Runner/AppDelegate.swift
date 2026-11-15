import ContactsUI
import Flutter
import MessageUI
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// The people of the debts (ADR 0030): the window of the contacts, an SMS
  /// and the window of sharing.
  private var people: PeopleChannel?

  /// The widgets of the home screen and what opens Birka from outside
  /// (ADR 0031).
  private var home: HomeChannel?

  /// The settings of Birka, where its camera can be allowed (ADR 0032).
  private var settings: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // A reminder of a payment shows while Birka is open too (ADR 0025).
    UNUserNotificationCenter.current().delegate = self
    if let registrar = registrar(forPlugin: "BirkaPeople") {
      people = PeopleChannel(messenger: registrar.messenger()) { [weak self] in
        self?.window?.rootViewController
      }
    }
    if let registrar = registrar(forPlugin: "BirkaHome") {
      home = HomeChannel(messenger: registrar.messenger())
    }
    if let registrar = registrar(forPlugin: "BirkaSettings") {
      settings = FlutterMethodChannel(
        name: "birka/settings", binaryMessenger: registrar.messenger())
      settings?.setMethodCallHandler { call, result in
        guard call.method == "open",
          let url = URL(string: UIApplication.openSettingsURLString)
        else {
          result(FlutterMethodNotImplemented)
          return
        }
        UIApplication.shared.open(url)
        result(nil)
      }
    }
    // A button of a widget, the control and Siri open the app and run here.
    if #available(iOS 18.0, *) {
      BirkaIntents.handler = { [weak self] action in
        self?.home?.deliver(action)
      }
    }
    // An action of the icon that launched Birka waits for Dart.
    if let item = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
      home?.deliver(item.type)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// An action of the icon while Birka runs (ADR 0031).
  override func application(
    _ application: UIApplication,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    home?.deliver(shortcutItem.type)
    completionHandler(true)
  }

  /// `birka://<action>` from a widget, the control or Siri (ADR 0031).
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "birka", let action = url.host, !action.isEmpty {
      home?.deliver(action)
      return true
    }
    return super.application(app, open: url, options: options)
  }
}

/// The channel `birka/people` (ADR 0030). The window of the contacts runs
/// apart from Birka and gives it only the contact picked, so Birka asks for
/// no access to the address book. A message opens for the person to send.
final class PeopleChannel: NSObject, CNContactPickerDelegate,
  MFMessageComposeViewControllerDelegate
{
  private let channel: FlutterMethodChannel
  private let host: () -> UIViewController?
  private var picking: FlutterResult?

  init(messenger: FlutterBinaryMessenger, host: @escaping () -> UIViewController?) {
    channel = FlutterMethodChannel(name: "birka/people", binaryMessenger: messenger)
    self.host = host
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result)
    }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    let text = arguments["text"] as? String ?? ""
    switch call.method {
    case "pickContact":
      pickContact(result)
    case "sendSms":
      sendSms(to: arguments["number"] as? String ?? "", text: text)
      result(nil)
    case "share":
      share(text)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// The screen on top, which a new window opens over.
  private func top() -> UIViewController? {
    var controller = host()
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }

  private func pickContact(_ result: @escaping FlutterResult) {
    guard picking == nil, let top = top() else { return result(nil) }
    picking = result
    let picker = CNContactPickerViewController()
    picker.delegate = self
    top.present(picker, animated: true)
  }

  func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
    let numbers: [[String: String]] = contact.phoneNumbers.map { labeled in
      let label = labeled.label.map {
        CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: $0)
      }
      return ["label": label ?? "", "number": labeled.value.stringValue]
    }
    let name = CNContactFormatter.string(from: contact, style: .fullName) ?? contact.givenName
    finishPicking(["name": name, "givenName": contact.givenName, "numbers": numbers])
  }

  func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    finishPicking(nil)
  }

  private func finishPicking(_ value: Any?) {
    picking?(value)
    picking = nil
  }

  /// An SMS where the phone sends them, and the window of sharing elsewhere,
  /// as on a simulator.
  private func sendSms(to number: String, text: String) {
    guard MFMessageComposeViewController.canSendText(), let top = top() else {
      return share(text)
    }
    let composer = MFMessageComposeViewController()
    composer.recipients = [number]
    composer.body = text
    composer.messageComposeDelegate = self
    top.present(composer, animated: true)
  }

  func messageComposeViewController(
    _ controller: MFMessageComposeViewController,
    didFinishWith result: MessageComposeResult
  ) {
    controller.dismiss(animated: true)
  }

  private func share(_ text: String) {
    guard let top = top() else { return }
    let sheet = UIActivityViewController(activityItems: [text], applicationActivities: nil)
    // An iPad shows the window as a popover, which needs a place.
    if let popover = sheet.popoverPresentationController {
      popover.sourceView = top.view
      popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.maxY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }
    top.present(sheet, animated: true)
  }
}
