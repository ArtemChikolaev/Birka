import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'cafe_journey.dart';
import 'native_journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('category limit survives saving, crossing it and reopening', (
    tester,
  ) async {
    await withNativeLedger(
      tester,
      name: 'category-limit',
      seed: seedCafeLedger,
      journey: (reopen) async {
        await observeCafeLimit(tester, '₽1,850 left', 'Starting limit');
        await tester.tapVisible(find.bySemanticsLabel('Back'));
        await spendAtCafe(tester, '1850', 'Cafe: ₽0 of ₽12,000 left');
        await observeCafeLimit(tester, '₽0 left', 'After saving ₽1,850');
        await tester.tapVisible(find.bySemanticsLabel('Back'));
        await spendAtCafe(tester, '1', 'Cafe: ₽1 over the limit');
        await observeCafeLimit(tester, '₽1 over', 'After saving ₽1');
        await reopen();
        await observeCafeLimit(tester, '₽1 over', 'After reopening SQLite');
      },
    );
  });
}
