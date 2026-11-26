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
  Future<Set<SignInMethod>> methods() async => {
    SignInMethod.email,
    SignInMethod.telegram,
  };
  @override
  Future<AccountProfile?> session() async => null;
  @override
  Future<String> request(
    SignInMethod method,
    String email,
    String language, {
    required bool link,
    required bool consent,
  }) async {
    address = email;
    return 'challenge';
  }

  @override
  Future<AccountVerification> verify(
    String challenge,
    String code, {
    required bool link,
  }) async {
    if (challenge != 'challenge' || code != '012345') throw AccountIssue.code;
    return address!.startsWith('+')
        ? const RegistrationProof('proof')
        : AccountProfile(email: address);
  }

  @override
  Future<AccountProfile> register(String proof) async =>
      const AccountProfile(telegram: '•••• 0123');
  @override
  Future<void> logout() async {
    address = null;
  }

  @override
  void close() {}
}

void main() {
  testWidgets(
    'guest access, email verification, transfer and explicit phone registration',
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
      await tester.tap(find.text(t.identity.telegram.toUpperCase()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '+12025550122');
      await tester.tap(find.byType(BirkaCheckbox));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '+1 (202) 555-0123');
      await tester.pumpAndSettle();
      expect(cubit.state.consent, isFalse);
      await tester.tap(find.byType(BirkaCheckbox));
      await tester.pumpAndSettle();
      await tap(t.identity.sendTelegram);
      expect(find.textContaining('•••• 0123'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '012345');
      await tap(t.identity.verify);
      expect(find.text(t.identity.confirmed), findsOneWidget);
      await tap(t.identity.create);
      expect(find.text('•••• 0123'), findsOneWidget);
      await tap(t.identity.logout);
      expect(find.text(t.identity.method), findsOneWidget);
    },
  );
}
