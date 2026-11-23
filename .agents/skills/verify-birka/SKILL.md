---
name: verify-birka
description: Verify category limits, quick-add spending and cross-currency transfers in Flutter or the built website, and backup restores and duplicate CSV imports on the web. Use when a change affects one of these journeys.
---

Choose the affected host and journey in the [feature map](references/feature-map.md).
Before changing the behavior, follow the card to the decision, shared rule
and its callers in both hosts. Reuse the rule at that boundary.
For Flutter, run the mapped command on macOS or pass a device ID. For the
website, build the current checkout once, then run the mapped command with
the same base path.

```sh
make build-web BASE=/Birka/
```

For a web transfer, the default command covers both supported test layouts.
To repeat either one, pass its width with `WIDTH=390` or `WIDTH=1440`.
For web runs, report the build ID, actual viewport and first failed step or observed values. Read `report.json` in the printed directory or the CI `web-verification`
artifact. Inspect `failure.png` when Chrome captured the failing page.
For loading or routing changes also run `make check-site BASE=/Birka/`. When a
change affects a mapped entry point, file format or expected result, drive
the affected journey and update its card in the same PR.

## When a web journey fails

1. Open the failed run's report. To check the build on its own, run
   `make doctor-web BASE=/Birka/` with the same base as the journey. A build
   for the wrong base can leave the Data page blank before the first click.
2. If the build passes, use the last observed page, the failing step and
   the screenshot to reproduce the symptom with the same fixture. Follow
   the value from the screen to the host or shared ledger until you find
   the first point where it differs from the scenario card.
3. For a regression, run a focused test through the public action on the
   old behavior. Record which assertion failed and the observed value.
   A setup or compilation failure calls for correcting the test setup first.
   Run the same test with the same expectations and fixtures on the fix.
   If an expectation changes, explain its source and repeat the baseline.
   Rebuild, repeat the original journey and link the report for that build
   alongside the two test outcomes in the PR.
