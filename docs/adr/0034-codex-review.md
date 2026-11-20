# ADR 0034 — Review pull requests with the ChatGPT subscription

**Status:** accepted 2026-11-20. Supersedes [ADR 0005](0005-claude-review.md).

Birka uses GitHub Code Review from the maintainer's ChatGPT plan. OpenAI
accounts for reviews through the plan's GitHub Code Review allowance. The
repository requires no OpenAI API key, copied CLI login or self-hosted runner.

## Setup for the maintainer

1. Sign in to ChatGPT with the account that owns the subscription and connect
   GitHub to Codex. Grant the GitHub integration access to
   `ArtemChikolaev/Birka`.
2. Open [Code review settings](https://chatgpt.com/settings/code-review),
   select Birka, and enable **Automatic review** under **Review code**. For
   a personal repository, choose whose PRs should be reviewed and the
   opening/ready trigger if available. When the repository follows personal
   preferences, enable **Automatic review** in personal preferences too.
3. On an existing PR, post `@codex review` from the connected GitHub
   account. An eyes reaction acknowledges the request. Verify that Codex
   subsequently posts its result. Repeat the command to request another pass
   after a fix.

## Project rules and routing

The root `AGENTS.md` points to `CLAUDE.md`. Its **Code Review Rules** section
covers money, persistence, dates, privacy and the two hosts. A focused request
can add a scope, for example `@codex review the Dart ledger migration and
compatibility with older backups`. Keep the review advisory and resolve its
threads under the existing branch protection.

The hosted integration documents automatic triggers and the PR comment
command. It does not document model selection by extension or label.
A GitHub label by itself is not wired to Codex in this repository.

[GitHub review integration](https://developers.openai.com/codex/integrations/github/)
and [usage accounting](https://developers.openai.com/codex/pricing/).
