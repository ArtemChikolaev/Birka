# ADR 0008 — The web host: a static Jaspr site on GitHub Pages

**Status:** accepted 2026-10-30.

## Context

- Birka runs in the browser too, on the same pure-Dart core as the Flutter
  app ([ADR 0001](0001-single-repository.md)), and anyone should be able to
  try it from a link.
- GitHub Pages serves static files under a subpath, `/Birka/`, with no
  rewrites and no custom headers.
- Most of a page needs no code in the browser, and a first visit should be
  quick.
- Flutter 3.38.10 keeps us on Jaspr 0.22 and `jaspr_router` 0.8.1
  ([ADR 0002](0002-toolchain.md)), which ignores `<base href>`.

## Decision

1. `apps/web` (`birka_web`) runs Jaspr in static mode: `jaspr build` renders
   every route to HTML at build time, and only the `@client` islands run in
   the browser.
2. The islands keep their state in the same BLoCs as the Flutter app, through
   `jaspr_bloc`.
3. `packages/design/jaspr` is the Jaspr kit, with the same components as the
   Flutter kit. Their `@css` styles use the custom properties of `tokens.css`.
4. Web fonts are WOFF2 subsets for Latin and Cyrillic, which `make web-fonts`
   cuts from the TTFs of the Flutter kit with fonttools. By `unicode-range`
   the browser fetches only the subsets a page needs.
5. Pages use paths relative to `<base href>`, which the build sets:
   `make build-web BASE=/Birka/`. The design packages keep their CSS and
   fonts in `lib/`, and the build serves them under `packages/<name>/`.
6. `ci.yml` builds the site on every pull request, and on `main` the `deploy`
   job publishes it to GitHub Pages once `All checks` has passed. The
   generated `*.options.dart` files are committed, so analysis needs no build,
   and the web job fails when they are stale.

## Options considered

| Option | Why not |
|---|---|
| Jaspr in client mode | the whole app in JavaScript, an empty page until it loads, and a 404 on Pages for a direct link to a nested route |
| Flutter on the web | draws on a canvas instead of a real DOM and starts slower; the site should read like a site |
| TTF on the web | 1 MB of fonts instead of 84 KB for a page in English |
| A stylesheet of the kit instead of `@css` | one more request, and styles away from their components |
| A separate deploy workflow | it would not know that the checks of the same commit passed |

## Consequences

- The first page is about 155 KB of JavaScript and 372 KB of files in all.
- `jaspr_router` 0.8.1 does not follow `<base href>`, so the second page has
  to deal with the `/Birka/` prefix itself or wait for a newer Jaspr.
- Static mode runs the component tree on the build machine: code that needs
  the browser, such as Drift, stays inside `@client` behind `@Import.onWeb`.
- `jaspr_bloc` follows state only in the browser, so tests on the VM call
  `setIsClientForTesting(true)`.
- The storage of Drift under the headers of Pages is still to be tried.
