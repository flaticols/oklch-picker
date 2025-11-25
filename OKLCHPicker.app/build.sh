#!/bin/bash

# Build script for OKLCH Picker macOS app

set -e

echo "🎨 Building OKLCH Color Picker..."

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf .build

# Build the app
echo "🔨 Building release version..."
swift build -c release

echo "✅ Build complete!"
echo ""
echo "To run the app:"
echo "  ./.build/release/OKLCHPicker"
echo ""
echo "Or use: swift run OKLCHPicker"
