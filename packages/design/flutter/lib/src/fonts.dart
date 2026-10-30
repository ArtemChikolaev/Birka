import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The package that bundles the fonts, which text styles name as their
/// `package`.
const String fontPackage = 'design_flutter';

/// The font families bundled with the design system. The tokens also list
/// web fallbacks such as `system-ui`, which Flutter does not know.
const Set<String> bundledFonts = {'Inter', 'Manrope'};

/// Lists the licenses of the bundled fonts on the app's license page.
///
/// Both fonts come under the SIL Open Font License, which asks to ship the
/// license along with the font. Call it once before `runApp`. The [bundle]
/// is for tests and defaults to the [rootBundle].
void registerFontLicenses({AssetBundle? bundle}) {
  LicenseRegistry.addLicense(() async* {
    for (final family in bundledFonts) {
      final license = await (bundle ?? rootBundle).loadString(
        'packages/$fontPackage/fonts/$family-OFL.txt',
      );
      yield LicenseEntryWithLineBreaks([family], license);
    }
  });
}
