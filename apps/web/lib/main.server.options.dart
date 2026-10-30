// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:birka_web/components/capital_preview.dart' as _capital_preview;
import 'package:birka_web/app.dart' as _app;
import 'package:design_jaspr/src/ambient_background.dart'
    as _ambient_background;
import 'package:design_jaspr/src/amount_text.dart' as _amount_text;
import 'package:design_jaspr/src/birka_head.dart' as _birka_head;
import 'package:design_jaspr/src/glass_surface.dart' as _glass_surface;
import 'package:design_jaspr/src/section_label.dart' as _section_label;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    _capital_preview.CapitalPreview:
        ClientTarget<_capital_preview.CapitalPreview>('capital_preview'),
  },
  styles: () => [
    ..._capital_preview.CapitalPreview.styles,
    ..._app.App.styles,
    ..._ambient_background.AmbientBackground.styles,
    ..._amount_text.AmountText.styles,
    ..._birka_head.birkaBaseStyles,
    ..._glass_surface.GlassSurface.styles,
    ..._section_label.SectionLabel.styles,
  ],
);
