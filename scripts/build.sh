#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
swift build -c release
bin_dir=$(swift build -c release --show-bin-path)
app="dist/Antigravity Account Switcher.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/AntigravitySwitcher" "$app/Contents/MacOS/AntigravitySwitcher"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>AntigravitySwitcher</string>
<key>CFBundleIdentifier</key><string>com.antigravity-account-switcher.app</string>
<key>CFBundleName</key><string>Antigravity Account Switcher</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
iconset=$(mktemp -d)/AppIcon.iconset
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" Icons/AppIcon_1024x1024_512x512@2x.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" Icons/AppIcon_1024x1024_512x512@2x.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"
cp Icons/MenuBar_Master_Black_1024x1024.png "$app/Contents/Resources/MenuBarIcon.png"
pinned=$(openssl x509 -in scripts/signing/release-certificate.pem -noout -fingerprint -sha1 | cut -d= -f2 | tr -d ':' | tr '[:lower:]' '[:upper:]')
if [[ "${UNSIGNED_BUILD:-0}" == 1 ]]; then
  identity="-"
else
  identity="${CODESIGN_IDENTITY:-$pinned}"
  if [[ "$identity" != "$pinned" ]]; then echo "Signing identity does not match the pinned certificate" >&2; exit 1; fi
  if ! security find-identity -p codesigning | grep -Fq "$pinned"; then echo "Pinned signing identity is unavailable" >&2; exit 1; fi
fi
sign_options=(--force --deep --sign "$identity")
if [[ -n "${CODE_SIGN_KEYCHAIN:-}" && "$identity" != "-" ]]; then sign_options+=(--keychain "$CODE_SIGN_KEYCHAIN"); fi
codesign "${sign_options[@]}" "$app"
codesign --verify --deep --strict "$app"
echo "Signing identity: $identity"
echo "Built $app"
