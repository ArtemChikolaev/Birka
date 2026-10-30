# ADR 0010 — Strings in one pure-Dart package with slang

**Status:** accepted 2026-10-30.

## Context

- Birka speaks Russian and English from the first version, on both hosts.
- Russian needs real plural rules: `в 1 счёте`, `в 2 счетах`, `в 21 счёте`.
- Flutter's `gen-l10n` writes code that only Flutter can use, and the core
  and the `common` packages are pure Dart
  ([ADR 0006](0006-feature-first-packages.md)).
- Amounts must keep every digit ([ADR 0003](0003-money-representation.md)).
  `NumberFormat` from `intl` formats through `double` unless it gets an
  `Int64`, and needs its locale data loaded first.

## Decision

1. `packages/core/l10n` holds the strings of every feature, one file per
   feature and language in `lib/i18n`: `accounts_ru.i18n.yaml` becomes
   `t.accounts`.
2. slang generates typed keys with plural rules. `make gen` runs it, the
   output is committed, and CI fails when it is stale.
3. English is the base language and the fallback. Every key exists in every
   language.
4. Everything reads the strings through the global `t` of the package, with
   no `BuildContext`. The host picks the language at startup, from the device
   until settings can change it.
5. `formatMoney` in the same package turns `Money` into text from its decimal
   digits, by the rules of the language.

## Options considered

| Option | Why not |
|---|---|
| `gen-l10n` with ARB files | its output depends on Flutter, so the web host could not use it |
| `slang_flutter` | gives a provider that rebuilds on a change of language, which one stream in the host can do without a dependency in every Flutter package |
| Strings in each feature | plural rules and terms drift apart, and a translator has to walk the whole tree |
| `NumberFormat` from `intl` | precision and locale data, as above |

## Consequences

- A new string means a key in every language and `make gen`.
- `t` is not reactive. When settings can change the language, the host has to
  rebuild from the root, listening to `LocaleSettings.getLocaleStream()`.
- Tests run in English unless they set a language.
- The first page of the site keeps its few lines in English in the code. Only
  an island knows the language of a visitor
  ([ADR 0008](0008-web-host.md)), and one on that page would bring all the
  strings to the lightest page of the site.
- Only currencies whose signs both fonts can draw get a sign; the others show
  their code.
