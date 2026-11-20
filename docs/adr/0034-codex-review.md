# ADR 0034 — An advisory Codex review of pull requests

**Status:** accepted 2026-11-20. Supersedes [ADR 0005](0005-claude-review.md).

Birka has lost access to its Claude reviewer. The replacement uses the
[official Codex Action](https://github.com/openai/codex-action) and keeps
review separate from the required `All checks` job.

## When it runs

| Change or label | Review |
| --- | --- |
| Any Dart file, or code in core, server or proto | GPT-6.2 Astra, high effort |
| Other code or workflow changes | GPT-6.2 Sol, medium effort |
| Docs, images, fonts or lockfiles alone | On request with `codex-review`, using Sol |
| `codex-strong` | Request Astra for any change |

Opening, reopening or marking a same-repository PR ready triggers selection.
Drafts, forks and bot PRs are skipped. A push alone does not start another
review. Apply or reapply either label for another pass on the current head.
A mixed change takes the stronger applicable model.

## Credentials, trust and publishing

Create the labels above and set an OpenAI project API key with model access
as the Actions repository secret `OPENAI_API_KEY`. This uses API billing.
The job posts a notice and skips when the secret is absent. Each review has a
20-minute timeout. The Codex Action has no equivalent of the former per-run
Claude dollar cap. Configure usage alerts and limits in the API project.

The workflow runs from the base branch on `pull_request_target`. The checkout
and review instructions come from the base commit. The reviewer reads the
proposed head with Git. It runs read-only under the action's drop-sudo policy,
with read-only repository permissions. A separate job publishes one COMMENT
review for the analyzed commit, with inline threads on the diff and a summary.
A stale, closed or draft PR is skipped before posting. Previous bot summaries
are supplied on rereview. The ruleset requires resolving threads before merge.
