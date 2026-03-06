#!/usr/bin/env bash
set -euo pipefail

# Builds and zips the self-contained app-image for the CURRENT OS.

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

patch_macos_plist() {
  # Ensures the app bundle Info.plist permits loading local dev servers in a JavaFX WebView.
  [[ "$(uname -s 2>/dev/null || true)" == "Darwin" ]] || return 0
  local buddy="/usr/libexec/PlistBuddy"
  [[ -x "$buddy" ]] || return 0

  local plist
  for plist in \
    "$ROOT_DIR/build/jpackage/AnonyChat.app/Contents/Info.plist" \
    "$ROOT_DIR/bin/macos/AnonyChat.app/Contents/Info.plist"
  do
    [[ -f "$plist" ]] || continue

    if ! "$buddy" -c "Print :NSAppTransportSecurity" "$plist" >/dev/null 2>&1; then
      "$buddy" -c "Add :NSAppTransportSecurity dict" "$plist" >/dev/null
    fi

    for key in NSAllowsArbitraryLoads NSAllowsArbitraryLoadsInWebContent; do
      if "$buddy" -c "Print :NSAppTransportSecurity:${key}" "$plist" >/dev/null 2>&1; then
        "$buddy" -c "Set :NSAppTransportSecurity:${key} true" "$plist" >/dev/null
      else
        "$buddy" -c "Add :NSAppTransportSecurity:${key} bool true" "$plist" >/dev/null
      fi
    done

    if ! "$buddy" -c "Print :NSAppTransportSecurity:NSExceptionDomains" "$plist" >/dev/null 2>&1; then
      "$buddy" -c "Add :NSAppTransportSecurity:NSExceptionDomains dict" "$plist" >/dev/null
    fi

    for domain in localhost 127.0.0.1; do
      if ! "$buddy" -c "Print :NSAppTransportSecurity:NSExceptionDomains:${domain}" "$plist" >/dev/null 2>&1; then
        "$buddy" -c "Add :NSAppTransportSecurity:NSExceptionDomains:${domain} dict" "$plist" >/dev/null
      fi

      for k in NSExceptionAllowsInsecureHTTPLoads NSIncludesSubdomains; do
        if "$buddy" -c "Print :NSAppTransportSecurity:NSExceptionDomains:${domain}:${k}" "$plist" >/dev/null 2>&1; then
          "$buddy" -c "Set :NSAppTransportSecurity:NSExceptionDomains:${domain}:${k} true" "$plist" >/dev/null
        else
          "$buddy" -c "Add :NSAppTransportSecurity:NSExceptionDomains:${domain}:${k} bool true" "$plist" >/dev/null
        fi
      done
    done

    if "$buddy" -c "Print :NSLocalNetworkUsageDescription" "$plist" >/dev/null 2>&1; then
      :
    else
      "$buddy" -c "Add :NSLocalNetworkUsageDescription string AnonyChat needs access to your local network to connect to local servers (e.g., localhost)." "$plist" >/dev/null
    fi
  done
}

./gradlew --no-daemon clean jpackage

patch_macos_plist || true

OUT_DIR="$ROOT_DIR/dist"
mkdir -p "$OUT_DIR"

if [[ -d "$ROOT_DIR/build/jpackage/AnonyChat.app" ]]; then
  ZIP_PATH="$OUT_DIR/AnonyChat-macos.zip"
  rm -f "$ZIP_PATH"
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$ROOT_DIR/build/jpackage/AnonyChat.app" "$ZIP_PATH"
  echo "Wrote: $ZIP_PATH"
else
  # Linux/Windows will produce a folder (layout differs). Zip the whole build/jpackage directory.
  ZIP_PATH="$OUT_DIR/AnonyChat-$(uname -s | tr '[:upper:]' '[:lower:]').zip"
  rm -f "$ZIP_PATH"
  (cd "$ROOT_DIR/build" && zip -qr "$ZIP_PATH" jpackage)
  echo "Wrote: $ZIP_PATH"
fi
