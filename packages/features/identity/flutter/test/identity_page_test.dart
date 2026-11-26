import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_common/identity_common.dart';
import 'package:identity_flutter/identity_flutter.dart';
import 'package:l10n/l10n.dart';

class _Access implements AccountAccess {
  String? address;
  @override
  Future<String?> session() async => null;
  @override
  Future<String> request(String email, String language) async {
    address = email;
    return 'challenge';
  }

  @override
  Future<String> verify(String challenge, String code) async {
    if (challenge != 'challenge' || code != '012345') throw AccountIssue.code;
    return address!;
  }

  @override
  Future<void> logout() async {
    address = null;
  }

  @override
  void close() {}
}

void main() {
  testWidgets(
    'a guest can leave, verify an email, read transfer steps and sign out',
    (tester) async {
      tester.view.physicalSize = const Size(780, 2000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      LocaleSettings.setLocaleSync(AppLocale.en);
      final cubit = IdentityCubit(_Access());
      addTearDown(cubit.close);
      var exits = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: BirkaTheme.dark(),
          home: BlocProvider.value(
            value: cubit,
            child: IdentityPage(
              onBack: () => exits++,
              onData: () {},
              accounts: 3,
              operations: 12,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String label) async {
        final target = find.widgetWithText(BirkaButton, label.toUpperCase());
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      expect(find.text(localRecordSummary(3, 12)!), findsOneWidget);
      await tap(t.identity.guest);
      expect(exits, 1);
      await tester.enterText(find.byType(TextField), 'guest@example.test');
      await tap(t.identity.send);
      expect(
        find.text(t.identity.sent(email: 'guest@example.test')),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), '000000');
      await tap(t.identity.verify);
      expect(find.text(t.identity.badCode), findsOneWidget);
      await tester.enterText(find.byType(TextField), '012345');
      await tap(t.identity.verify);
      expect(find.text('guest@example.test'), findsOneWidget);
      await tap(t.identity.copy);
      expect(find.textContaining(t.identity.copyRestore), findsOneWidget);
      await tap(t.identity.copyBack);
      await tap(t.identity.logout);
      expect(find.text(t.identity.entry), findsOneWidget);
    },
  );
}
