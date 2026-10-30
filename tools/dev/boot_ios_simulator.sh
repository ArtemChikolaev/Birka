#!/usr/bin/env bash
# Boots an iOS simulator for `flutter run` and waits until it is ready.
# BIRKA_IOS_DEVICE picks the device by name; the default is the first
# available iPhone. Does nothing if an iPhone simulator is already booted.
set -euo pipefail

if xcrun simctl list devices booted | grep -q 'iPhone'; then
  exit 0
fi

device="${BIRKA_IOS_DEVICE:-$(xcrun simctl list devices available |
  grep -m 1 -oE 'iPhone[^(]*' | sed 's/ *$//')}"
if [ -z "$device" ]; then
  echo 'No iPhone simulator found. Add one in Xcode > Settings > Components.' >&2
  exit 1
fi

echo "Booting $device"
xcrun simctl bootstatus "$device" -b
open -a Simulator
