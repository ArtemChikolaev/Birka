# The design canvas

Birka was designed on a Claude Design canvas, «Birka · Ночь»: 161 boards of
the phone app and the site, from the first screens in October 2026 to the
limits of categories in November. That canvas lived in an account that is
gone. This folder is what was recovered from the transcripts of the sessions
that drew it, and the canvas
[Birka · Ночь](https://claude.ai/artifact/HWbDNV7NtL5RoBHrLiXqhf) is published
again from it.

The folder is laid out as the canvas's `project/` folder:

| File | What it is |
|---|---|
| `canvas.json` | the index: where each board sits, its title, and the titles of the rows |
| `*.dc.html` | one board each, a live page with its states and motion |
| `birka-app-icon.png` | the icon that the notification boards show; the same file as `apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png` |
| `lost/` | screenshots of boards whose source was not recovered |

The boards run on the runtime of the Design type (`support.js`), so they open
on the canvas, not as files in a browser. Every name, amount and phone
number in them is made up.

## How complete it is

- 38 boards were in the last copy of the canvas on disk.
- 94 boards were rebuilt by replaying the writes, edits and build scripts of
  those sessions. Each one is byte for byte the size the canvas reported
  when it was last published.
- `Motion-Push.dc.html` came back from an earlier version, 70 bytes short of
  the last one.
- 28 boards are lost. The eight wide pages of the site were snapshots of the
  live site taken with a script, and the 20 boards built on top of them
  could not be rebuilt without them. Of these, 23 have screenshots in
  `lost/`:

| Lost board | Screenshot |
|---|---|
| Categories, accounts, an account, a new account, reports, «Ещё», help and data on the site, wide | `lost/Web-*-Wide.png` |
| Import with regular payments found on the site | `lost/Web-Import-Found-*.png` |
| Tags on the site, the tag of an operation, a tag and a new tag | `lost/Web-Tags-*.png`, `lost/Web-Tag-*.png`, `lost/Web-Operation-Tags-*.png` |
| «Спросить» on the site | `lost/Web-Ask-*.png` |
| Debts on the site, a debt and a new debt; people in debts, wide | `lost/Web-Debt-*.png`, `lost/Web-People-Wide-1440.png` |

There is no picture of five of them: categories on the site (wide), the way
into «Спросить» from the overview and the operations it finds on the phone,
and a person and a new person in debts on the site (narrow). The site
itself implements all of these pages, so the live site is their reference
now.

## Changing the canvas

When the canvas changes on claude.ai, read the changed files back into this
folder in the same pull request. To publish this folder again, publish to the
canvas's address with the Artifact tool: `root` is a folder that holds these
files under `project/`, `file_path` is `project/canvas.json`, and `files`
lists the boards.
