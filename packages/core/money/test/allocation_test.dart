import 'dart:math';

import 'package:money/money.dart';
import 'package:test/test.dart';

Money rub(int minorUnits) => Money(minorUnits, Currency.rub);

int sumOf(List<Money> parts) =>
    parts.fold(0, (sum, part) => sum + part.minorUnits);

void main() {
  test('on a tie the leftover goes to the earlier parts', () {
    expect(rub(10000).split(3), [rub(3334), rub(3333), rub(3333)]);
    expect(rub(5).allocate([1, 1]), [rub(3), rub(2)]);
  });

  test('the leftover goes to the parts that lost the most in rounding', () {
    // Exact shares 3.33 and 6.67 round to 3 and 7, not 4 and 6.
    expect(rub(10).allocate([1, 2]), [rub(3), rub(7)]);
    // Found by the property test below: the first share is exact, so it
    // must not get the extra kopeck.
    expect(rub(-1661876769).allocate([4, 3, 3, 2]), [
      rub(-553958923),
      rub(-415469192),
      rub(-415469192),
      rub(-276979462),
    ]);
  });

  test('keeps the sign of negative amounts', () {
    expect(rub(-10000).split(3), [rub(-3334), rub(-3333), rub(-3333)]);
  });

  test('follows the ratios', () {
    expect(rub(1000).allocate([70, 20, 10]), [rub(700), rub(200), rub(100)]);
    expect(rub(100).allocate([1, 0, 1]), [rub(50), rub(0), rub(50)]);
  });

  test('gives nothing to a part with a zero ratio', () {
    expect(rub(101).allocate([0, 1, 1]), [rub(0), rub(51), rub(50)]);
  });

  test('stays exact for the largest amount', () {
    final parts = rub(Money.maxMinorUnits).allocate([1, 2, 3]);
    expect(sumOf(parts), Money.maxMinorUnits);
    expect(parts.map((part) => part.minorUnits), [
      1501199875790165,
      3002399751580330,
      4503599627370496,
    ]);
  });

  test('rejects meaningless ratios', () {
    expect(() => rub(100).allocate([]), throwsArgumentError);
    expect(() => rub(100).allocate([1, -1]), throwsArgumentError);
    expect(() => rub(100).allocate([0, 0]), throwsArgumentError);
    expect(() => rub(100).split(0), throwsRangeError);
  });

  test('parts always add up to the amount and stay within one minor unit '
      'of the exact share', () {
    final random = Random(20261029);
    for (var run = 0; run < 2000; run++) {
      final magnitude = random.nextInt(0x7fffffff);
      final amount = random.nextBool() ? magnitude : -magnitude;
      final ratios = List.generate(1 + random.nextInt(6), (_) {
        return random.nextInt(5);
      });
      if (ratios.every((ratio) => ratio == 0)) ratios[0] = 1;
      final total = ratios.reduce((a, b) => a + b);

      final parts = rub(amount).allocate(ratios);

      expect(sumOf(parts), amount, reason: '$amount by $ratios');
      for (var i = 0; i < ratios.length; i++) {
        final exact = amount * ratios[i] / total;
        expect(
          (parts[i].minorUnits - exact).abs(),
          lessThan(1),
          reason: 'part $i of $amount by $ratios',
        );
        if (ratios[i] == 0) expect(parts[i].isZero, isTrue);
      }
    }
  });
}
