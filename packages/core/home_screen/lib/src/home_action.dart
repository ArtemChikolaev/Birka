/// What the person opens Birka with from outside its window: a widget, an
/// action of its icon, a control or Siri (ADR 0031).
enum HomeAction {
  /// The overview, from the body of «Сегодня».
  overview,

  /// The money until the salary, from «Сегодня» while no salary is set.
  payday,

  /// A new expense.
  expense,

  /// A new income.
  income,

  /// A new transfer.
  transfer,

  /// A question in words.
  ask
  ;

  /// The action that the platform calls [name], or `null` for one this
  /// version does not know.
  static HomeAction? named(String? name) =>
      values.where((action) => action.name == name).firstOrNull;
}
