import 'package:money/money.dart';
import 'package:rates/rates.dart';
import 'package:test/test.dart';

void main() {
  test('tells the choice to whoever comes first', () async {
    final base = BaseCurrency(Currency.eur);

    expect(await base.watch().first, Currency.eur);
  });

  test('tells every later choice', () async {
    final base = BaseCurrency(null);
    final seen = <Currency?>[];
    final subscription = base.watch().listen(seen.add);
    await pumpEventQueue();

    base.choose(Currency.usd);
    await pumpEventQueue();
    base.choose(null);
    await pumpEventQueue();
    await subscription.cancel();

    expect(seen, [null, Currency.usd, null]);
    expect(base.value, isNull);
  });
}
