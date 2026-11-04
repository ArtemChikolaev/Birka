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
- Birka is in early development: its first releases are for trying it out,
  and the owner makes the key of the releases later.

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
   `docs/releases/X.Y.Z.md` holds its notes.
4. The build number follows from the version, `X * 10000 + Y * 100 + Z`, so
   that each release comes after the one before: 0.1.0 is 100.
5. With the key, `apksigner` checks the APK before anything is published, and
   a certificate of a debug key stops the release. The APK `birka-vX.Y.Z.apk`
   then goes into a draft release with the notes, and the release is
   published after it, as the latest.
6. Until the key is in the secrets, a release is a test build. Its APK signs
   with the debug key of its run, the note of `docs/releases/test-build.md`
   stands above its notes, and it is published as a pre-release, never as
   the latest. The note says that the next release will not install over it
   and that the records move over through a copy in «Данные».
7. A release APK carries native libraries for arm64 alone. Flutter builds
   its engine and the app for `--target-platform`, arm64 in `make build-apk`,
   while the plugins bring libraries for more ABIs. Gradle keeps a release
   build to the ABIs of that flag, so a phone without arm64 refuses the APK
   instead of installing an app that cannot start, and `make build-apk`
   stops on an APK with another ABI.

## Options considered

| Option | Why not |
|---|---|
| The debug key for every release | every release would ask to remove the app and its records first; only the test builds do |
| A test key of its own in the secrets | the owner would keep two keys, and the move to the key of the releases would still ask to reinstall |
| The key in the repository | in the open anyone could sign an update of Birka; encrypted, its password still has to live somewhere, and the key would sit in every clone |
| Play App Signing through Google Play | Birka is not in the stores yet; the release key can still go there later |
| The run number as the build number | it restarts with a new workflow and says nothing about the version |
| Flutter for 32-bit ARM and x86_64 too | the APK would carry the engine and the app once more for each, for few phones |

## Consequences

- The key cannot be replaced without asking everyone to reinstall: the owner
  keeps a copy of it and of its passwords outside the repository.
- Each test build asks to reinstall, and so does the first release with the
  key. Releases with the key install over each other.
- Phones without arm64, the old 32-bit ones among them, cannot install
  Birka. The APK of 0.1.0 still carries libraries of other ABIs, so there it
  installs and does not start.
- A release is a merged release pull request with its notes and version,
  then a tag pushed by the owner.
- An iOS build waits for an account of Apple.
