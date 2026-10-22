#!/usr/bin/env bash
# Installs the Android SDK pieces the build needs (no emulator) and points Gradle at it.
set -euo pipefail

SDK="${ANDROID_HOME:-$HOME/android-sdk}"
TOOLS_ZIP=commandlinetools-linux-16111833_latest.zip
TOOLS_SHA1=e025545c62a8e64c7559119566a569fb1dec5f60

if [ ! -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ]; then
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/tools.zip" "https://dl.google.com/android/repository/$TOOLS_ZIP"
  echo "$TOOLS_SHA1  $tmp/tools.zip" | sha1sum -c -
  mkdir -p "$SDK/cmdline-tools"
  unzip -q "$tmp/tools.zip" -d "$tmp"
  mv "$tmp/cmdline-tools" "$SDK/cmdline-tools/latest"
  rm -rf "$tmp"
fi

yes | "$SDK/cmdline-tools/latest/bin/sdkmanager" --licenses > /dev/null
"$SDK/cmdline-tools/latest/bin/sdkmanager" --install "platforms;android-36" "build-tools;35.0.0" > /dev/null

echo "sdk.dir=$SDK" > local.properties
echo "Android SDK ready at $SDK"
