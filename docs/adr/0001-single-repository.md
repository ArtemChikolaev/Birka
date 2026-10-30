# ADR 0001 — One repository with three zones

**Status:** accepted 2026-10-29.

## Context

- Birka has three parts with different jobs: the app (a pure-Dart core shared
  by a Flutter app and a Jaspr web app), a design system (tokens, fonts,
  icons, Flutter and Jaspr component kits) and, later, a small Go server that
  relays end-to-end encrypted sync messages.
- We considered a repository per part. A separate repository pays off when
  parts have different owners, several consumers and a settled contract
  between them. Here one developer builds all three, the design system and
  the server have a single consumer, the app, and tokens, components and the
  sync protocol will change together with the screens.
- Similar products moved the other way. Ente (Flutter apps, a Go server,
  end-to-end encryption) archived its separate app repositories and moved them
  into one. Actual Budget archived `actual-server` and moved the sync server
  into its main repository.

## Decision

1. One repository with three zones, each with its own root:

| Zone | Where | Root | Boundary |
|---|---|---|---|
| App | `apps/`, `packages/core/`, `packages/features/` ([ADR 0006](0006-feature-first-packages.md)) | the Dart workspace, one `pubspec.lock` | core and `*/common` packages are pure Dart |
| Design system | `packages/design/` | the same Dart workspace | depends on nothing from the core or features |
| Server | `server/`, `proto/` (later) | its own `go.mod` and `buf.yaml` | shares only `proto/` with the app; `buf breaking` guards compatibility |

2. CI checks the boundaries on every pull request (`make check-deps`), so
   they do not depend on review alone.
3. Our packages depend on each other through `path:`. Inside the workspace a
   version constraint would also work, but outside it the same constraint is
   looked up on pub.dev.

## Options considered

| Option | Why not |
|---|---|
| Three repositories: app, design system, server | every UI change becomes a kit PR, a tag, a version bump and an app PR; local work through git refs and `pubspec_overrides.yaml`; three CI setups, three sets of agent rules; sync end-to-end tests only against a published server image |
| Two repositories: the app with the design system, and the server | during sync work the protocol changes together with the client, so the same costs apply to the server |

## Consequences

- One pull request can carry a change through every layer: token, component,
  screen and test, or protocol field, server and client.
- CI runs per zone with path filters; the server gets its own workflow and
  `server-v*` tags when it appears.
- A part moves to its own repository when one of these happens:

| Part | Trigger | How |
|---|---|---|
| Design system | a second product uses it, or we publish it on pub.dev as a standalone library with docs and semver | `git filter-repo --path packages/design` keeps the history; packages get a `birka_` prefix |
| Server | it gets its own contributors or self-hosting users, or needs a different license or release cycle | `git filter-repo --path server --path proto`; the app generates its client from a server tag |
