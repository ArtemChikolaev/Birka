import 'package:birka_web/hide_amounts_cubit.dart';
import 'package:test/test.dart';

void main() {
  test('starts with the amounts shown and toggles them', () {
    final cubit = HideAmountsCubit();
    addTearDown(cubit.close);
    expect(cubit.state, isFalse);

    cubit.toggle();
    expect(cubit.state, isTrue);

    cubit.toggle();
    expect(cubit.state, isFalse);
  });
}
