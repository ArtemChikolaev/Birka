# ADR 0007 — Design tokens in DTCG with our own generator

**Status:** accepted 2026-10-30.

## Context

- The mockups set the look of Birka: a black base with emerald accents,
  Liquid Glass surfaces, a faint glow in the corners, Manrope for headings
  and amounts, Inter for running text.
- The Flutter app and the Jaspr web app must look the same. Values copied by
  hand into two kits drift apart.
- The Design Tokens Community Group format (DTCG, stable since 2025.10) is a
  JSON format that design tools and token pipelines read and write.
- Birka is local-first: the app should not fetch fonts from the network at
  startup.
- Inter and Manrope come as variable fonts. With `fontWeight` alone, Flutter
  keeps the default instance of a variable font and thickens it
  artificially; the default instance of Manrope is ExtraLight.

## Decision

1. The tokens live in `packages/design/tokens/tokens/*.tokens.json` in the
   DTCG format: a palette of raw colors and named roles that alias it,
   sizes, effects, motion and typography. Birka's own flags, such as
   uppercase and tabular figures, go into `$extensions` under
   `io.github.artemchikolaev.birka`.
2. Our generator, `make tokens`, writes `lib/src/tokens.g.dart`, pure-Dart
   constants for both kits, and `lib/css/tokens.css`, custom properties and
   text classes for the web. It supports the subset of DTCG that Birka uses and
   rejects anything else with the name of the token. The generated files are
   committed, and `make check-tokens` fails in CI when they are out of date.
3. `packages/design/flutter` turns the tokens into a `ThemeData` with two
   extensions, `BirkaColors` and `BirkaTextStyles`, and holds the shared
   widgets: `GlassSurface`, `AmbientBackground`, `AmountText` and
   `SectionLabel`. It re-exports the tokens, so a feature depends on it
   alone.
4. The fonts are bundled: the variable Inter and Manrope from google/fonts,
   with their SIL Open Font License shown on the license page. Every text
   style sets its weight both as `fontWeight` and on the `wght` axis, and
   Inter also gets its optical size.
5. The design system knows nothing about money: an amount is a formatted
   string with a tone.

## Options considered

| Option | Why not |
|---|---|
| Style Dictionary | a Node toolchain in a Dart repository for one transformation; our generator is a few hundred lines with tests |
| Constants written by hand in each kit | Flutter and the web drift apart, with no single source |
| The `google_fonts` package | fetches fonts from Google at runtime by default; bundling with it still needs the files in the repository |
| A static font file per weight | google/fonts ships Inter and Manrope only as variable fonts; five files per family instead of one |
| Generating with `build_runner` | slower builds, and nobody reviews the output; committed files show every change in the diff |

## Consequences

- A token changes in the JSON, then `make tokens`; the pull request shows
  the change in the generated files too.
- Only the dark theme exists. A light theme adds a second set of role colors.
- Shadows are not tokens yet: the floating navigation bar will add the DTCG
  `shadow` type when it lands.
- The Jaspr kit takes `tokens.css` as it is and its own WOFF2 subsets of the
  same fonts ([ADR 0008](0008-web-host.md)).
