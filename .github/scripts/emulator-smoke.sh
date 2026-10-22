#!/usr/bin/env bash
# Smoke test for a debug APK on a running emulator: installs it on a clean device, opens the
# terminal straight away (the first launch unpacks the bundled runtime meanwhile), waits for the
# bundled bash, checks yt-dlp through the terminal's own shell functions and fails on crashes/ANRs.
#
# usage: emulator-smoke.sh <dir-with-x86_64-apk> <output-dir>
set -euo pipefail

APK_DIR="$1"
OUT="$2"
PKG=com.deniscerri.ytdl
mkdir -p "$OUT"

apk=$(ls "$APK_DIR"/*.apk | head -1)
adb install -r -g "$apk"
adb shell settings put global hide_error_dialogs 1
adb logcat -c

adb shell am start -a ytdlnis.TerminalActivity -n "$PKG/.ui.more.terminal.TerminalActivity"

started=""
for i in $(seq 1 60); do
  if adb shell ps -A -o ARGS | grep -q 'terminal_local/bash/bash'; then
    started=$((i * 5))
    break
  fi
  sleep 5
done

finish() {
  adb exec-out screencap -p > "$OUT/terminal.png" || true
  adb logcat -d > "$OUT/logcat.txt" || true
  adb logcat -d -b crash > "$OUT/crash.txt" || true
}

if [ -z "$started" ]; then
  finish
  echo "::error::The terminal's bash session did not start within 300 s"
  exit 1
fi
echo "Terminal shell started after ~${started}s"

# Type a command into the terminal itself for the screenshot (the prompt is pre-filled with
# "yt-dlp "); `input text` would read a leading "--" as an option, so send the dashes as keys.
adb shell input keyevent KEYCODE_MINUS KEYCODE_MINUS
adb shell input text version
adb shell input keyevent KEYCODE_ENTER
sleep 10

# Check yt-dlp with the same shell functions the terminal defines.
version=$(adb shell "run-as $PKG sh -c '. ./terminal_local/shellrc >/dev/null 2>&1; yt-dlp --version'" | tr -d '\r' | tail -1)
echo "yt-dlp --version: $version"

finish

status=0
if ! [[ "$version" =~ ^[0-9]{4}\.[0-9]{2}\.[0-9]{2} ]]; then
  echo "::error::yt-dlp did not report a version through the terminal environment"
  status=1
fi
if grep -q "$PKG" "$OUT/crash.txt"; then
  echo "::error::The app crashed (see crash.txt)"
  status=1
fi
if grep -q "ANR in $PKG" "$OUT/logcat.txt"; then
  echo "::error::The app was not responding (see logcat.txt)"
  status=1
fi
exit $status
