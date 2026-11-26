import 'package:identity_common/identity_common.dart';
import 'package:identity_jaspr/identity_jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_bloc/testing.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:l10n/l10n.dart';

void main() {
  testComponents('an unconfigured service leaves an exit to the local app', (
    tester,
  ) async {
    setIsClientForTesting(true);
    addTearDown(resetIsClientForTesting);
    final cubit = IdentityCubit(null);
    addTearDown(cubit.close);
    var exits = 0;
    tester.pumpComponent(
      BlocProvider.value(
        value: cubit,
        child: IdentityPage(onBack: () => exits++, accounts: 0, operations: 0),
      ),
    );
    await tester.pump();
    expect(find.text(t.identity.offline), findsOneComponent);
    expect(find.text(t.identity.empty), findsOneComponent);
    await tester.click(
      find.ancestor(
        of: find.text(t.identity.guest),
        matching: find.tag('button'),
      ),
    );
    expect(exits, 1);
  });
}
