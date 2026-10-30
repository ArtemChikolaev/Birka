#!/usr/bin/env bash
# Starts an Android emulator for `flutter run` and waits until it has booted.
# BIRKA_AVD picks the virtual device; the default is the first one listed.
# Does nothing if an emulator is already running.
set -euo pipefail

sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
adb="$sdk/platform-tools/adb"
emulator="$sdk/emulator/emulator"

if "$adb" devices | grep -q '^emulator-'; then
  exit 0
fi

# The emulator prints INFO lines before the list of devices.
avd="${BIRKA_AVD:-$("$emulator" -list-avds 2>/dev/null | grep -v '^INFO' |
  head -n 1)}"
if [ -z "$avd" ]; then
  echo 'No Android virtual device found. Create one in Android Studio.' >&2
  exit 1
fi

echo "Starting $avd"
nohup "$emulator" -avd "$avd" >/dev/null 2>&1 &
"$adb" wait-for-device
until [ "$("$adb" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; do
  sleep 1
done
