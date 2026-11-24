#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="CleanDisk"

if [ ! -d "$DIR/$APP_NAME.app" ]; then
    echo "App bundle not found. Building now..."
    "$DIR/build.sh"
fi

echo "🚀 Launching $APP_NAME into the macOS Menu Bar..."
open "$DIR/$APP_NAME.app"
echo "Look for the ✨ sparkles icon in your top macOS menu bar!"
