# ADR 0020 — Releases of the Android app

**Status:** accepted 2026-11-04.

## Context

- A release is a `vX.Y.Z` tag on `main`, its files go into a draft first, and
  a published release is immutable ([ADR 0004](0004-branches-and-releases.md)).
- Android installs an update only over an app signed with the same key. The
  APK of every CI run signs with a debug key of its own, so none of them can
  update another.
- The key and its passwords are secrets: they live with the owner and in the
  secrets of the repository, never in the code.

## Decision

1. The owner keeps one key of the releases. The repository holds it in the
   secrets `ANDROID_KEYSTORE` (the keystore in base64),
   `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`.
2. Gradle signs a release build with that key when `BIRKA_KEYSTORE` names
   the keystore, with the passwords and the alias in `BIRKA_KEYSTORE_PASSWORD`,
   `BIRKA_KEY_ALIAS` and `BIRKA_KEY_PASSWORD`. Without it a release build signs
   with the debug key, as `flutter run --release` and the APK of every pull
   request do.
3. `release.yml` runs on a pushed tag `vX.Y.Z`. It checks that the tag stands
   on `main`, that `apps/mobile/pubspec.yaml` has the version `X.Y.Z` and that
   `docs/releases/X.Y.Z.md` holds its notes. Without the key it fails, because
   an APK with a debug key could not be updated by the next release.
4. The build number follows from the version, `X * 10000 + Y * 100 + Z`, so
   that each release comes after the one before: 0.1.0 is 100.
5. Before anything is published, `apksigner` checks the APK, and a
   certificate of a debug key stops the release. The APK `birka-vX.Y.Z.apk`
   then goes into a draft release with the notes, and the release is
   published after it, as the latest.

## Options considered

| Option | Why not |
|---|---|
| The debug key for releases | every release would ask to remove the app and its records first |
| The key in the repository, encrypted | a password still has to live somewhere, and the key would sit in every clone |
| Play App Signing through Google Play | Birka is not in the stores yet; the release key can still go there later |
| The run number as the build number | it restarts with a new workflow and says nothing about the version |

## Consequences

- The key cannot be replaced without asking everyone to reinstall: the owner
  keeps a copy of it and of its passwords outside the repository.
- A release is a merged release pull request with its notes and version,
  then a tag pushed by the owner.
- An iOS build waits for an account of Apple.
