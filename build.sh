#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="CleanDisk"
APP_BUNDLE="$DIR/$APP_NAME.app"
CACHE_DIR="/tmp/cleandisk-build-cache"

echo "🧹 Compiling $APP_NAME..."
mkdir -p "$CACHE_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Generate or update vector icon if needed
if [ ! -f "$DIR/Resources/AppIcon.icns" ]; then
    echo "🎨 Generating vector app icon..."
    swiftc -module-cache-path "$CACHE_DIR" "$DIR/Resources/generate_icon.swift" -o /tmp/gen_icon
    /tmp/gen_icon "$DIR/Resources/AppIcon.icns"
fi

# Copy icon into bundle
cp "$DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Compile all Swift files
swiftc -parse-as-library \
    -module-cache-path "$CACHE_DIR" \
    -O \
    "$DIR/Sources/CleanDiskApp.swift" \
    "$DIR/Sources/Models/CleanResult.swift" \
    "$DIR/Sources/Models/VolumeItem.swift" \
    "$DIR/Sources/Services/CleanerEngine.swift" \
    "$DIR/Sources/Services/VolumeMonitor.swift" \
    "$DIR/Sources/Services/FileSystemWatcher.swift" \
    "$DIR/Sources/ViewModels/CleanDiskViewModel.swift" \
    "$DIR/Sources/Views/VolumeCardView.swift" \
    "$DIR/Sources/Views/DropZoneView.swift" \
    "$DIR/Sources/Views/CleanDiskMainView.swift" \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Create Info.plist with icon and LSUIElement
cat << 'EOF' > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CleanDisk</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.CleanDisk</string>
    <key>CFBundleName</key>
    <string>CleanDisk</string>
    <key>CFBundleDisplayName</key>
    <string>CleanDisk</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Codesign for Apple Silicon execution
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✨ Successfully built: $APP_BUNDLE"
echo "👉 Launch with: ./run.sh or 'open $APP_NAME.app'"
