#!/bin/sh
# Builds dist/NautaConnect.app from the SwiftPM release binary.
set -eu

cd "$(dirname "$0")/.."

VERSION="0.1.0"
APP="dist/NautaConnect.app"

swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp ".build/release/NautaConnect" "$APP/Contents/MacOS/NautaConnect"
cp "assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>NautaConnect</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.nautaconnect.macos</string>
	<key>CFBundleName</key>
	<string>NautaConnect</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>CFBundleVersion</key>
	<string>${VERSION}</string>
	<key>LSMinimumSystemVersion</key>
	<string>12.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
PLIST

# Ad-hoc signature so Gatekeeper lets the local build run.
codesign --force -s - "$APP"

echo "Built $APP"
