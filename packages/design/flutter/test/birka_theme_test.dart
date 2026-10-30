import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = BirkaTheme.dark();

  test('carries Birka colors and text styles as extensions', () {
    expect(theme.extension<BirkaColors>(), same(BirkaColors.dark));
    expect(
      theme.extension<BirkaTextStyles>(),
      same(BirkaTextStyles.standard),
    );
  });

  test('gives Material the colors of the tokens', () {
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, const Color(BirkaTokens.colorAccent));
    expect(theme.colorScheme.error, const Color(BirkaTokens.colorNegative));
    expect(
      theme.scaffoldBackgroundColor,
      const Color(BirkaTokens.colorBackground),
    );
  });

  test('keeps Manrope in headings and Inter in running text', () {
    expect(
      theme.textTheme.headlineLarge?.fontFamily,
      'packages/design_flutter/Manrope',
    );
    expect(
      theme.textTheme.bodyMedium?.fontFamily,
      'packages/design_flutter/Inter',
    );
    expect(
      theme.textTheme.bodyMedium?.color,
      const Color(BirkaTokens.colorText),
    );
  });

  testWidgets('of falls back to the defaults outside a Birka theme', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      Theme(
        data: ThemeData(),
        child: Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(BirkaColors.of(context), same(BirkaColors.dark));
    expect(BirkaTextStyles.of(context), same(BirkaTextStyles.standard));
  });
}
