"""Select the reviewer for the complete three-dot diff, including deletions."""

import os
from pathlib import PurePosixPath
import sys


def select_model(paths, asked, strong):
    assets = {".md", ".txt", ".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg",
              ".ico", ".ttf", ".otf", ".woff", ".woff2"}
    code = False
    for name in paths:
        path = PurePosixPath(name)
        if path.suffix == ".dart":
            strong = True
        if (name.startswith("docs/") or path.suffix.lower() in assets or
                path.name in {"LICENSE", "pubspec.lock", "go.sum"}):
            continue
        code = True
        if name.startswith(("packages/core/", "server/", "proto/")):
            strong = True
    if strong:
        return "gpt-6.2-astra", "high"
    if code or asked:
        return "gpt-6.2-sol", "medium"
    return None


if __name__ == "__main__":
    paths = (os.fsdecode(name) for name in sys.stdin.buffer.read().split(b"\0") if name)
    choice = select_model(paths, os.environ["ASKED"] == "true", os.environ["STRONG"] == "true")
    if choice:
        print(f"model={choice[0]}")
        print(f"effort={choice[1]}")
    else:
        print("Docs/assets only. Add codex-review to request a review.", file=sys.stderr)
