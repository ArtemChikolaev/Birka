import 'package:home_screen/src/home_action.dart';
import 'package:home_screen/src/widget_snapshot.dart';

/// The home screen of the phone as the host reaches it: the widgets that
/// draw the figures of the day, the adding of a widget from the app, and the
/// actions that open Birka (ADR 0031).
abstract interface class HomeScreen {
  /// Hands [snapshot] to the widgets and asks them to draw it again.
  Future<void> show(WidgetSnapshot snapshot);

  /// Whether the launcher can add a widget when the app asks.
  Future<bool> canPin();

  /// Asks the launcher to add «Сегодня», and says whether it asked the
  /// person.
  Future<bool> pin();

  /// What the person opens Birka with: the action that launched it comes
  /// first, once.
  Stream<HomeAction> get actions;

  /// A widget that the launcher added when the app asked.
  Stream<void> get pinned;
}
