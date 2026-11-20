---
name: verify-birka
description: Verify monthly category limits, quick-add previews and saved expenses in the built Birka web app. Use for changes that can affect this user journey.
---

From the repository root, build the current checkout and run the category-limit
journey against that build. Use the same base path in both commands.

```sh
make build-web BASE=/Birka/
make verify-web FLOW=category-limit BASE=/Birka/
```

Read [the category-limit flow](references/category-limit.md) for the starting
data, actions and expected results. The command starts its own server and
browser. Report the first failed step or the observed values after reload.
For a change to loading, routing or another page, also run the repository's
`make check-site` with the same base.
