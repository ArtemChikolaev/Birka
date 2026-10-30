# Brand

The app icon of Birka: a glass coin with a milled edge and the letter B in
Manrope ExtraBold, on a black base with an emerald glow. It is the coin from
the [mockups](../../../docs/design/).

| File | What it is |
|---|---|
| `coin.svg` | the source: the full icon on 1024 × 1024, with groups for the background, the coin and a one-color version |
| `render.html` | shows one variant of `coin.svg` for rendering |
| `png/` | the masters that the platform icons and launch screens come from |

## Variants

| Master | Where it goes |
|---|---|
| `icon.png` | iOS, where the system rounds the corners, and the home screen icon of the site |
| `icon-dark.png` | the dark and tinted icons of iOS 18: the coin without the background |
| `icon-foreground.png`, `icon-background.png` | the adaptive icon of Android: the coin, smaller, and the background as separate layers |
| `icon-monochrome.png` | the themed icon of Android 13, which the system paints in one color |
| `icon-macos.png` | macOS, Android before 8 and the favicon of the site, which show an icon as it is: a rounded tile with a shadow |
| `launch.png` | the launch screens of iOS and of Android before 12: the coin on black |
| `launch-android-12.png` | the launch icon of Android 12, whose glow fades out before the circle Android cuts it to |

## Changing the icon

1. Edit `coin.svg`. It renders in a browser through a local server, which
   loads the Manrope font for the letter.
2. `make icon-masters` renders the masters with headless Chrome:
   `tools/dev/render_icons.sh`.
3. `make icons` writes the platform icons with `flutter_launcher_icons` and
   scales the launch images and favicons with `sips`:
   `tools/dev/apply_icons.sh`. It needs macOS.
4. Look at the result in the iOS simulator and the Android emulator.

The launch screens are plain platform files: `LaunchScreen.storyboard` on
iOS, `launch_background.xml` and the themes on Android. They are written by
hand rather than with `flutter_native_splash`, which is a Flutter plugin:
even as a dev dependency it would bring CocoaPods into the app and its code
into debug builds.
