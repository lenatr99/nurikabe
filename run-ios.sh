#!/usr/bin/env bash
set -euo pipefail

# ==== CONFIG ====
SCHEME="Nurikabe"
CONFIGURATION="Debug"
SIMULATOR_NAME="iPhone 16"   # exact device name you want
BUNDLE_ID="TwinsDev.Nurikabe"
DERIVED_DATA_PATH="build"

# Console verbosity controls
LOG_LEVEL="${LOG_LEVEL:-default}"  # default | info | debug
LOG_PREDICATE="(process == \"${SCHEME}\") OR (subsystem BEGINSWITH[c] \"${BUNDLE_ID}\") OR (senderImagePath CONTAINS[c] \"/${SCHEME}.app/\") OR (processImagePath CONTAINS[c] \"/${SCHEME}.app/\")"
# =================

log() { echo -e "$1"; }

timestamp=$(date +%Y%m%d_%H%M%S)
mkdir -p "$DERIVED_DATA_PATH"
BUILD_LOG="$DERIVED_DATA_PATH/build_$timestamp.log"

# --- Helper: resolve simulator UDID (prefer Booted, then first Available), no awk/PCRE
find_udid() {
  local name="$1" udid=""
  udid=$(
    xcrun simctl list devices 2>/dev/null \
      | grep -iF "$name (" \
      | grep -i "Booted" \
      | sed -n 's/.*(\([0-9A-Fa-f-][0-9A-Fa-f-]*\)).*/\1/p' \
      | head -n1 || true
  )
  if [[ -z "$udid" ]]; then
    udid=$(
      xcrun simctl list devices available 2>/dev/null \
        | grep -iF "$name (" \
        | sed -n 's/.*(\([0-9A-Fa-f-][0-9A-Fa-f-]*\)).*/\1/p' \
        | head -n1 || true
    )
  fi
  printf '%s' "$udid"
}

# --- Helper: kill any leftover console sessions for this UDID or scheme
kill_prev_console() {
  local udid="$1" name="$2"
  set +e
  if pgrep -fl "simctl spawn.*${udid}.*log stream" >/dev/null 2>&1; then
    log "🧹 Killing previous console sessions (by UDID $udid)..."
    pkill -f "simctl spawn.*${udid}.*log stream" || true
  fi
  if pgrep -fl "log stream.*${name}" >/dev/null 2>&1; then
    log "🧹 Killing previous console sessions (by name '$name')..."
    pkill -f "log stream.*${name}" || true
  fi
  set -e
}

log "🖥️ Ensuring Simulator app is running..."
if ! pgrep -x "Simulator" >/dev/null 2>&1; then
  open -ga "Simulator" || true
  sleep 1
fi

log "🔎 Looking for simulator matching: $SIMULATOR_NAME"
UDID="$(find_udid "$SIMULATOR_NAME")"
if [[ -z "$UDID" ]]; then
  log "❌ No simulator matching '$SIMULATOR_NAME' was found."
  echo "Here are your available iOS simulators:"
  xcrun simctl list devices available | sed -n 's/^[[:space:]]*//p'
  exit 1
fi
log "✅ Found UDID: $UDID"

# Boot and focus that exact device
if ! xcrun simctl list devices booted | grep -qF "$UDID"; then
  log "🌀 Booting simulator $SIMULATOR_NAME..."
  xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
fi
log "⏳ Waiting for simulator to be ready..."
xcrun simctl bootstatus "$UDID" -b
open -a "Simulator" --args -CurrentDeviceUDID "$UDID" || true

log "📦 Building $SCHEME for device id=$UDID..."

XCB_CMD=(xcodebuild build
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "id=$UDID"
  -derivedDataPath "$DERIVED_DATA_PATH"
)

# Build with nice output if xcbeautify is available, while preserving exit code
if command -v xcbeautify >/dev/null 2>&1; then
  set +e
  "${XCB_CMD[@]}" 2>&1 | tee "$BUILD_LOG" | xcbeautify
  build_status=${PIPESTATUS[0]}
  set -e
else
  set +e
  "${XCB_CMD[@]}" 2>&1 | tee "$BUILD_LOG"
  build_status=${PIPESTATUS[0]}
  set -e
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

# Locate the .app (Debug-iphonesimulator)
APP_PATH="$PWD/$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION-iphonesimulator/$SCHEME.app"
if [[ ! -d "$APP_PATH" ]]; then
  log "❌ App not found at $APP_PATH"
  log "   (Check scheme/configuration names.)"
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

log "🎛  Cleaning up old console sessions (if any)..."
kill_prev_console "$UDID" "$SCHEME"

log "📱 Opening quieter console monitor in a new Terminal window..."
if command -v osascript >/dev/null 2>&1; then
  # Read script from stdin ("-") and pass UDID, scheme, level, predicate as argv
  osascript - "$UDID" "$SCHEME" "$LOG_LEVEL" "$LOG_PREDICATE" <<'OSA'
on run argv
  set theUDID to item 1 of argv
  set theScheme to item 2 of argv
  set theLevel to item 3 of argv
  set thePredicate to item 4 of argv
  set banner to "📱 Console Monitor for " & theScheme & " (UDID: " & theUDID & ") — level: " & theLevel
  set cmd to "echo " & quoted form of banner & "; echo; " & ¬
            "xcrun simctl spawn " & quoted form of theUDID & " log stream --style compact --level " & theLevel & " --predicate " & quoted form of thePredicate
  tell application "Terminal"
    do script cmd
    activate
  end tell
end run
OSA
else
  # Fallback: run in current shell
  xcrun simctl spawn "$UDID" log stream --style compact --level "$LOG_LEVEL" --predicate "$LOG_PREDICATE" &
fi


log "🎉 Done! Simulator is open, app is running, and console is filtered."
echo "Full build log saved to: $BUILD_LOG"
