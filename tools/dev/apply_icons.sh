#!/usr/bin/env bash
# Turns the icon masters in packages/design/brand/png into the app icons and
# launch screens of apps/mobile and the favicons of apps/web:
# flutter_launcher_icons writes the app icons, and sips scales the rest. Run it after
# tools/dev/render_icons.sh. Needs macOS for sips.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
png="$root/packages/design/brand/png"
app="$root/apps/mobile"

(cd "$app" && dart run flutter_launcher_icons -f flutter_launcher_icons.yaml)
# flutter_launcher_icons 0.14.4 also sets an unrelated Xcode setting to
# AppIcon; put it back.
perl -pi -e 's/(GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = )AppIcon;/${1}YES;/' \
  "$app/ios/Runner.xcodeproj/project.pbxproj"

# scale <master> <pixels> <file>
scale() {
  sips -z "$2" "$2" "$1" --out "$3" >/dev/null
}

# Before Android 12, launch_image is the coin at 256 dp. Android 12 draws its
# own icon, launch_icon, at 288 dp with the coin inside a 192 dp circle.
res="$app/android/app/src/main/res"
for spec in mdpi:256:288 hdpi:384:432 xhdpi:512:576 xxhdpi:768:864 \
  xxxhdpi:1024:1152; do
  IFS=: read -r density image icon <<<"$spec"
  mkdir -p "$res/drawable-$density"
  scale "$png/launch.png" "$image" \
    "$res/drawable-$density/launch_image.png"
  scale "$png/launch-android-12.png" "$icon" \
    "$res/drawable-$density/launch_icon.png"
done

# iOS centers LaunchImage, 256 points wide, on black.
images="$app/ios/Runner/Assets.xcassets/LaunchImage.imageset"
scale "$png/launch.png" 256 "$images/LaunchImage.png"
scale "$png/launch.png" 512 "$images/LaunchImage@2x.png"
scale "$png/launch.png" 768 "$images/LaunchImage@3x.png"

# The site: the rounded tile as the favicon, the full icon for iOS home
# screens.
web="$root/apps/web/web"
scale "$png/icon-macos.png" 64 "$web/favicon.png"
scale "$png/icon.png" 180 "$web/apple-touch-icon.png"
echo "Updated the icons and launch screens of apps/mobile and apps/web."
