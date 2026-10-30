import 'package:birka_mobile/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the app name', (tester) async {
    await tester.pumpWidget(const BirkaApp());

    expect(find.text('Birka'), findsOneWidget);
  });
}
