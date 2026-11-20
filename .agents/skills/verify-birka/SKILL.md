---
name: verify-birka
description: Verify category limits, quick-add spending, and backup downloads and restores in the built Birka web app. Use when a change affects one of these journeys.
---

Choose a journey in the [feature map](references/feature-map.md). Build the
current checkout once, then run its command with the same base path.

```sh
make build-web BASE=/Birka/
```

Report the first failed step or the values read back from the app. For
loading or routing changes also run `make check-site BASE=/Birka/`. When a
change affects a mapped entry point, file format or expected result, drive
the affected journey and update its card in the same PR.
