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

Report the first failed step or the values read back from the app. For
loading or routing changes also run `make check-site BASE=/Birka/`. When a
change affects a mapped entry point, file format or expected result, drive
the affected journey and update its card in the same PR.
