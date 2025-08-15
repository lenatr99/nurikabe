#!/usr/bin/env bash
set -euo pipefail

# ==== CONFIG ====
SCHEME="Nurikabe"
CONFIGURATION="Debug"
SIMULATOR_NAME="iPhone 16"
BUNDLE_ID="TwinsDev.Nurikabe"
DERIVED_DATA_PATH="build"
# =================

log() { echo -e "$1"; }

timestamp=$(date +%Y%m%d_%H%M%S)
mkdir -p "$DERIVED_DATA_PATH"
BUILD_LOG="$DERIVED_DATA_PATH/build_$timestamp.log"

log "📦 Building $SCHEME for $SIMULATOR_NAME..."

# Build and capture status correctly
XCB_CMD=(xcodebuild build
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "platform=iOS Simulator,name=$SIMULATOR_NAME"
  -derivedDataPath "$DERIVED_DATA_PATH"
)

if command -v xcbeautify >/dev/null 2>&1; then
  "${XCB_CMD[@]}" 2>&1 | tee "$BUILD_LOG" | xcbeautify
  build_status=${PIPESTATUS[0]}
else
  "${XCB_CMD[@]}" 2>&1 | tee "$BUILD_LOG"
  build_status=${PIPESTATUS[0]}
fi

if [[ ${build_status:-1} -ne 0 ]]; then
  log "❌ Build failed"
  echo "—— Error summary ——"
  grep -nE "error: " "$BUILD_LOG" | sed 's/^/   /' | tail -n 50 || true
  echo
  echo "Full log: $BUILD_LOG"
  exit 1
fi

log "✅ Build succeeded"

# Prefer a booted simulator UDID; otherwise first available
UDID=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep Booted | sed -n 's/.*(\([A-F0-9-]\{36\}\)).*/\1/p' | head -n1)
if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl list devices available | grep "$SIMULATOR_NAME" | sed -n 's/.*(\([A-F0-9-]\{36\}\)).*/\1/p' | head -n1)
fi

if [[ -z "$UDID" ]]; then
  log "❌ Simulator '$SIMULATOR_NAME' not found"
  exit 1
fi

# Ensure the Simulator app itself is running
if ! pgrep -x "Simulator" >/dev/null 2>&1; then
  log "🖥️ Opening Simulator app..."
  open -a "Simulator"
  sleep 1
fi

# Boot simulator if needed
if ! xcrun simctl list devices booted | grep -q "$UDID"; then
  log "🌀 Booting simulator $SIMULATOR_NAME..."
  xcrun simctl boot "$UDID" || true
fi

log "⏳ Waiting for simulator to be ready..."
xcrun simctl bootstatus "$UDID" -b

# Ensure the correct device window is shown in the Simulator app
open -a "Simulator" --args -CurrentDeviceUDID "$UDID" || true

# Locate the .app
APP_PATH="$PWD/$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION-iphonesimulator/$SCHEME.app"
if [[ ! -d "$APP_PATH" ]]; then
  log "❌ App not found at $APP_PATH"
  log "   (Did the scheme/configuration names match your project?)"
  exit 1
fi

# Install (replace if already installed) + launch
log "📲 Installing $APP_PATH to simulator $UDID..."
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP_PATH"

log "🚀 Launching $BUNDLE_ID..."
if ! xcrun simctl launch "$UDID" "$BUNDLE_ID"; then
  log "❌ Launch failed (is the bundle id correct?)"
  exit 1
fi

log "✅ Done!"
echo "Full build log saved to: $BUILD_LOG"
echo

# Open console monitoring in a new terminal window
log "📱 Opening console monitor in new terminal window..."

# Kill any existing log streams for this process to avoid duplicates
pkill -f "log stream.*$SCHEME" >/dev/null 2>&1 || true
sleep 0.5

# Open new terminal window with console monitoring
osascript <<EOF
tell application "Terminal"
    do script "echo '📱 Console Monitor for $SCHEME'; echo 'App logs will appear below:'; echo; xcrun simctl spawn '$UDID' log stream --predicate 'process == \"$SCHEME\"' --style compact"
    activate
end tell
EOF

log "🎉 Console monitor opened in new terminal window!"
echo "   You can now interact with the app and see debug output in real-time."
