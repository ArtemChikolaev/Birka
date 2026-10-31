/// The fragments that led to the current one, which tells what lies one step
/// back in the history of the browser.
class FragmentTrail {
  final _steps = <String>[];

  /// Whether one step back leads to [fragment].
  bool leadsBackTo(String fragment) => _steps.lastOrNull == fragment;

  /// Notes that the page moved from [from] to [to]: a step back leaves the
  /// trail, and any other step adds to it.
  void moved({required String from, required String to}) {
    if (leadsBackTo(to)) {
      _steps.removeLast();
    } else {
      _steps.add(from);
    }
  }
}
