import 'dart:async';

import 'package:reports_common/reports_common.dart';

/// Keeps what the reports read in memory.
final class FakeReportsRepository implements ReportsRepository {
  /// Creates a repository.
  FakeReportsRepository({this.main, this.monthList = const []});

  /// The currency of the first account that counts.
  Currency? main;

  /// The currency picked for totals.
  Currency? base;

  /// The kept rates.
  RateBook rates = const RateBook.empty();

  /// The rows of each kind.
  final days = <CategoryKind, List<CategoryDayTotal>>{};

  /// The months with operations.
  List<CivilDate> monthList;

  /// The error of the next read.
  Exception? readFailure;

  /// The kinds and days that the rows were asked for.
  final asked = <(CategoryKind, CivilDate, CivilDate)>[];

  final _rows = StreamController<void>.broadcast();
  final _main = StreamController<void>.broadcast();

  /// Tells those who follow that something changed.
  void changed() {
    _rows.add(null);
    _main.add(null);
  }

  /// Tells those who follow the rows, and nobody else, that they changed.
  void changedRows() => _rows.add(null);

  /// Sends an error to those who follow the main currency.
  void breakMain(Object error) => _main.addError(error);

  Stream<T> _follow<T>(
    StreamController<void> changes,
    T Function() read,
  ) => Stream.multi((controller) {
    if (readFailure case final failure?) {
      controller.addError(failure);
    } else {
      controller.add(read());
    }
    final subscription = changes.stream.listen(
      (_) => controller.add(read()),
      onError: controller.addError,
    );
    controller.onCancel = () => unawaited(subscription.cancel());
  });

  @override
  Stream<Currency?> watchMainCurrency() => _follow(_main, () => main);

  @override
  Stream<Currency?> watchBaseCurrency() => _follow(_main, () => base);

  /// The day the months start on.
  int start = 1;

  @override
  int monthStart() => start;

  @override
  Stream<int> watchMonthStart() => Stream.value(start);

  @override
  Stream<RateBook> watchRates() => _follow(_main, () => rates);

  @override
  Stream<List<CategoryDayTotal>> watchDays(
    CategoryKind kind, {
    required CivilDate from,
    required CivilDate to,
  }) {
    asked.add((kind, from, to));
    return _follow(_rows, () => days[kind] ?? const []);
  }

  @override
  Future<List<CivilDate>> months({int start = 1}) async {
    if (readFailure case final failure?) throw failure;
    return monthList;
  }
}

/// What went through a category for tests.
CategoryTotal testTotal(String name, Money total) => CategoryTotal(
  Category(
    id: name,
    kind: CategoryKind.expense,
    name: name,
    archived: false,
    sortOrder: 0,
  ),
  total,
);

/// What went through a category on [day] for tests.
CategoryDayTotal testDay(String name, CivilDate day, Money total) {
  final CategoryTotal(:category) = testTotal(name, total);
  return CategoryDayTotal(category, day, total);
}
