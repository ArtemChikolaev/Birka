# ADR 0005 — An advisory Claude review of pull requests

**Status:** accepted 2026-10-30.

## Context

- One developer writes Birka with coding agents, so most changes have no
  second reader.
- The repository is public: anyone can open a pull request or comment on one,
  and everything in a pull request is untrusted input.
- `main` takes changes only through pull requests with green checks
  ([ADR 0004](0004-branches-and-releases.md)).
- A review of a pull request that only adds images or edits docs costs
  usage and finds nothing.

## Decision

1. `.github/workflows/claude-review.yml` runs `anthropics/claude-code-action`,
   pinned to a full commit SHA, when a same-repository pull request is opened,
   reopened or marked ready for review. Drafts, forks and pull requests from
   bots are skipped.
2. The review runs automatically only when the pull request changes code.
   Docs, images, fonts and lockfiles alone get no automatic review. The
   `claude-review` label asks for a review of any pull request, and for
   another one after changes.
3. The review is advisory: it is not a required check and stays outside
   `All checks`. Its comments are review threads, and the ruleset for `main`
   requires every thread to be resolved, so each finding gets an answer.
4. The credential is a Claude subscription token (`claude setup-token`) in
   the `CLAUDE_CODE_OAUTH_TOKEN` repository secret. Without the secret the job
   skips with a notice.
5. The job uses `GITHUB_TOKEN` with `contents: read` and `pull-requests: write`
   instead of the Claude GitHub App, so the review can read the repository and
   comment, and nothing else.
6. Claude may only read code, run `gh pr view`, `gh pr diff` and
   `gh pr comment`, and post inline comments. Editing, writing and web tools
   are removed, and tokens are scrubbed from the environment of its shell
   commands.
7. The model is Sonnet 5.5, or Opus 5.5 when the pull request touches core
   packages, `server/` or `proto/`, or carries the `claude-opus` label. A run
   stops after 40 turns, $5 of estimated usage or 20 minutes.
8. The rules come from `CLAUDE.md` on the base branch, which the action
   restores before the run, so a pull request cannot rewrite the rules it is
   reviewed against. The review-specific instructions are in the workflow's
   prompt: the severity levels Important, Nit (at most three) and
   Pre-existing, and the Birka checklist (boundaries, money, dates, toolchain,
   CI rules, privacy).

## Options considered

| Option | Why not |
|---|---|
| Anthropic's managed Code Review | available only on Team and Enterprise plans and billed separately |
| An API key | billed per review, while the subscription already covers this use |
| The Claude GitHub App | write access to contents and workflows, more than a review needs |
| GitHub Copilot code review | reads its instructions from the pull request's own branch |
| CodeRabbit | another vendor whose model and prompts we do not control |
| A review of every pull request | wastes usage on pull requests that only add assets or docs |
| A required review check | outages, usage limits or false positives would block merges |

## Consequences

- Reviews use the same subscription limits as interactive work, and a run
  fails when they are used up.
- The token lives for a year and must be replaced before it expires.
- Pull requests from forks get no automatic review: their runs have no
  secrets. The maintainer reviews them.
- A new core package must be added to the model rule in the workflow, and a
  new kind of asset to the list of files that get no automatic review.
- Changes to `CLAUDE.md` affect reviews only after they are merged.
