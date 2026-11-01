# ADR 0011 — Settings of a device live outside the database

**Status:** accepted 2026-11-01.

## Context

- The first settings are the language and whether the amounts start hidden.
  Both belong to one device: a phone in Russian says nothing about a laptop in
  English, so sync should not carry them.
- A page of the site needs its language before it shows a word, and the
  database opens in a worker, after the page has appeared
  ([ADR 0008](0008-web-host.md), [ADR 0009](0009-data-model.md)). A language
  read from the database would flash the wrong one first.
- More reads no data and opens no database, and it is where the settings
  stand.
- `common` packages are pure Dart ([ADR 0006](0006-feature-first-packages.md)),
  and each host has its own place to keep small values.

## Decision

1. `packages/core/device_settings` defines `SettingsStore`: `read` of a string,
   which is immediate, and `write`. `Settings` turns those strings into typed
   values, so the keys and the defaults live in one place. They started in the
   settings feature and moved when the onboarding needed them
   ([ADR 0013](0013-onboarding.md)).
2. The hosts implement the store: `localStorage` on the web, and
   `shared_preferences` with its cache on phones, opened before `runApp`.
3. Every key has a default, and what is missing or unknown falls back to it. A
   browser that refuses its storage keeps the settings for one page.
4. No chosen language means following the device, and the choice can go back
   to that.
5. The host redraws on `LocaleSettings.getLocaleStream()`, because `t` is not
   reactive ([ADR 0010](0010-strings.md)). The app builds a new router on the
   location that stands open, and More on the site rebuilds its island.
6. Hidden amounts at launch are a starting point, not a second eye. The eye
   still decides until the app closes, and on the site until the tab closes.

## Options considered

| Option | Why not |
|---|---|
| A table in the Drift database | the site would flash the wrong language and More would have to open the database, and rows of one device do not belong in the schema that sync carries |
| The database on phones and `localStorage` on the web | two ways to read one setting, and a migration for two values |
| A file of our own beside the database | atomic writes and corrupted files to look after, for what a first-party plugin already does |
| `SharedPreferences` without the cache, or `SharedPreferencesAsync` | reading has to be immediate, and the cache gives that on the current API |
| Keeping the state of the eye between launches | the eye would change what the next launch shows without saying so; the mockup has a switch, which says it |

## Consequences

- A setting that stored data depends on goes into the database with its own
  decision. The base currency does not: every total is computed when it is
  read ([ADR 0012](0012-exchange-rates.md)).
- A backup of the database does not carry these settings.
- A language picked in one tab reaches other open tabs when they load a page.
- On the site, a tab that has not touched the eye follows the switch from its
  next page, because every page is a new document.
