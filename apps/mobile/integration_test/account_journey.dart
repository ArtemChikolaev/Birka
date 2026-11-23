import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transactions_flutter/transactions_flutter.dart';

import 'native_journey.dart';

/// Reads the balance and the signed entries on the open account page.
Future<void> checkAccountHistory(
  WidgetTester tester, {
  required String balance,
  required List<String> amounts,
}) async {
  final page = find.byType(AccountPage);
  final card = find.descendant(
    of: page,
    matching: find.byType(AccountCard),
  );
  await tester.observeText(
    find.descendant(of: card, matching: find.text(balance)),
    'Account balance',
  );
  final rows = find.descendant(
    of: page,
    matching: find.byType(OperationRow),
  );
  for (final amount in amounts) {
    final label = find.descendant(of: rows, matching: find.text(amount));
    await tester.scrollUntilVisible(
      label.hitTestable(),
      160,
      scrollable: find
          .descendant(of: page, matching: find.byType(Scrollable))
          .first,
    );
    await tester.observeText(label, 'Account entry');
  }
  expect(rows, findsNWidgets(amounts.length));
}
