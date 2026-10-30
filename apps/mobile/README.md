# birka_mobile

The Flutter host of Birka: Android and iOS, plus macOS during development.
It wires features, the router and the theme together; the logic lives in the
packages ([ADR 0006](../../docs/adr/0006-feature-first-packages.md)).

```bash
make run-mobile                  # macOS, the quickest loop
make run-mobile DEVICE=iPhone    # a booted iOS simulator
make run-mobile DEVICE=emulator  # a running Android emulator
```

In VS Code, pick a configuration under Run and Debug: it boots the simulator
or the emulator first.
