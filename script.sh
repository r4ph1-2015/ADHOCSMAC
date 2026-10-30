#!/bin/bash

APP_PATH="$HOME/Applications/steam.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Opera GX not found at $APP_PATH"
    exit 1
fi

echo "🔄 Starting deep ad-hoc signing..."

# 1. Strip all old code signatures and attributes completely
echo "🧹 Clearing old signatures and extended attributes..."
rm -rf "$APP_PATH/_CodeSignature"
find "$APP_PATH" -name "_CodeSignature" -exec rm -rf {} + 2>/dev/null
xattr -cr "$APP_PATH"

# 2. Sign EVERY single nested component from the deepest level up
echo "✍️ Forcing ad-hoc signatures on all nested files..."
# This finds frameworks, plugins, helpers, and all executable binaries
find "$APP_PATH" \( -name "*.framework" -o -name "*.app" -o -name "*.dylib" -o -name "*.bundle" -o -type f -perm +111 \) | while read -r component; do
    if [ "$component" != "$APP_PATH" ]; then
        # Force ad-hoc sign without enforcing strict Hardened Runtime constraints on sub-components
        codesign --force --sign - "$component" 2>/dev/null
    fi
done

# 3. Explicitly sign the specific failing framework version from your log
echo "✍️ Targeting the primary Opera Framework..."
FRAMEWORK_PATH="$APP_PATH/Contents/Frameworks/Opera Framework.framework"
if [ -d "$FRAMEWORK_PATH" ]; then
    codesign --force --sign - "$FRAMEWORK_PATH"
fi

# 4. Sign the root application bundle 
echo "✍️ Signing the main outer application bundle..."
# Note: We omit '--options runtime' here because Hardened Runtime strictly triggers Team ID verification.
codesign --force --sign - "$APP_PATH"

echo "🔍 Verifying parent app signature..."
codesign -dvvv "$APP_PATH"

echo "🔍 Verifying framework signature..."
codesign -dvvv "$APP_PATH/Contents/Frameworks/Opera Framework.framework"

echo "✅ Done! Try launching the app again."
