---
name: verify-birka
description: Verify category limits and quick-add spending in Flutter or the built website, and backup transfers and duplicate CSV imports on the web. Use when a change affects one of these journeys.
---

Choose the affected host and journey in the [feature map](references/feature-map.md).
For Flutter, run the mapped command on macOS or pass a device ID. For the
website, build the current checkout once, then run the mapped command with
the same base path.

```sh
make build-web BASE=/Birka/
```

Report the first failed step or the values read back from the app. For web
runs, read `report.json` in the printed directory or the CI `web-verification`
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
3. For a regression, capture that difference in a focused failing test.
   After the fix, repeat the test and the original journey with a fresh
   build. Cite the two outcomes and the new report in the PR.
