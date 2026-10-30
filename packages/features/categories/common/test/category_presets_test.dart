import 'package:categories_common/categories_common.dart';
import 'package:l10n/l10n.dart';
import 'package:test/test.dart';

void main() {
  test('every preset has a name in every language', () {
    for (final locale in AppLocale.values) {
      final names = locale.buildSync().categories.presets;
      for (final preset in categoryPresets) {
        expect(names[preset.key], isNotNull, reason: preset.key);
      }
    }
  });

  test('presets use icons and colors from the sets', () {
    for (final preset in categoryPresets) {
      expect(categoryIcons, contains(preset.icon));
      expect(categoryColors, contains(preset.color));
    }
  });

  test('presets cover both kinds and have no duplicates', () {
    expect(categoryPresets.map((p) => p.kind).toSet(), CategoryKind.values);
    final keys = categoryPresets.map((preset) => preset.key);
    expect(keys.toSet(), hasLength(keys.length));
  });

  test('the colors are written as #rrggbb', () {
    expect(categoryColors, hasLength(7));
    expect(categoryColors, everyElement(matches(RegExp(r'^#[0-9a-f]{6}$'))));
  });
}
