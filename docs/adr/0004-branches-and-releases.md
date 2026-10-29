# ADR 0004 — GitHub flow with a protected main

**Status:** accepted 2026-10-29.

## Context

- One developer builds Birka, and coding agents open pull requests too.
- `main` must always build and pass its tests: the web demo is deployed from
  it and releases are tagged on it.
- Discipline alone does not keep `main` green: a direct push or a merge with
  red checks is one click away, for the owner as well.

## Decision

1. The branching model is GitHub flow: a short-lived branch from `main`, one
   pull request, a squash merge. There is no `develop` branch.
2. `main` is the release line. A release is a `vX.Y.Z` tag on `main`, made
   after its release pull request is merged.
3. A repository ruleset protects `main`. Its bypass list is empty, so it binds
   the owner too:
   - no deletion, no force push, linear history;
   - changes land only through a pull request with every review thread
     resolved, merged with squash;
   - no approval is required, because GitHub does not let authors approve
     their own pull requests;
   - the `All checks` status check from GitHub Actions must pass on a branch
     that is up to date with `main`.
4. `All checks` is the last job of `ci.yml`. It needs every other job, runs
   with `if: always()` and fails when any of them failed or was cancelled.
   GitHub counts a skipped job as passed, so without `always()` a failed test
   would skip the gate and let the pull request through.
5. Workflows that produce required checks have no path filters: GitHub leaves
   the checks of a filtered-out workflow pending, and the pull request cannot
   be merged. Jobs that matter only for some paths use `if:` conditions.
6. A second ruleset forbids moving and deleting `v*` and `server-v*` tags, and
   published releases are immutable.
7. Rulesets live as JSON in [.github/rulesets](../../.github/rulesets/). A
   change to them goes through a pull request; the owner then applies it by
   importing the file (Settings → Rules → Rulesets → New ruleset → Import a
   ruleset) or with `gh api`.

## Options considered

| Option | Why not |
|---|---|
| git flow with `develop` | twice the pull requests and CI runs plus back-merges, with no gain for one developer |
| Every CI job as a required check | each new job would mean a settings change, and jobs limited to some paths would leave pull requests pending |
| Classic branch protection | a ruleset does the same, restricts merge methods and can be imported from a JSON file |
| A merge queue | available only to repositories owned by an organization |

## Consequences

- A new CI job gates merges only after it is added to the `needs` of
  `All checks`.
- Release automation must not open pull requests with `GITHUB_TOKEN`: CI runs
  on pull requests from `github-actions[bot]` wait for a manual approval, so
  the required check would not arrive. It will use a GitHub App token.
- Release files are uploaded to a draft release before it is published.
- The owner can still edit or disable the rulesets in the settings: they
  protect `main` from accidents, not from its owner.
