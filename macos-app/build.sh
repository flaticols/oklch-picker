#!/bin/bash

# Build script for OKLCH Picker macOS app

set -e

PROJECT="OKLCHPicker.xcodeproj"
SCHEME="OKLCHPicker"
CONFIGURATION="${1:-Release}"

echo "🎨 Building OKLCH Color Picker for macOS..."
echo "Configuration: $CONFIGURATION"
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found. Please install Xcode."
    exit 1
fi

# Clean build folder
echo "🧹 Cleaning previous build..."
rm -rf build/

# Build the app
echo "🔨 Building $SCHEME..."
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath build \
    clean build

# Find the built app
APP_PATH="build/Build/Products/$CONFIGURATION/OKLCHPicker.app"

if [ -d "$APP_PATH" ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "App location: $APP_PATH"
    echo ""
    echo "To run the app:"
    echo "  open \"$APP_PATH\""
    echo ""
    echo "To install to Applications:"
    echo "  cp -r \"$APP_PATH\" /Applications/"
else
    echo ""
    echo "❌ Build failed - app not found at $APP_PATH"
    exit 1
fi
