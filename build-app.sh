#!/usr/bin/env bash
# Build Murmur.app from the swift package.
# Produces ./Murmur.app — drop into /Applications and add to Accessibility.

set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Murmur"
BUNDLE="${APP_NAME}.app"
BUILD_CFG="release"

echo "==> Compiling (${BUILD_CFG})…"
swift build -c "${BUILD_CFG}"

BIN_PATH="$(swift build -c "${BUILD_CFG}" --show-bin-path)/${APP_NAME}"
if [[ ! -x "${BIN_PATH}" ]]; then
    echo "Build failed: binary missing at ${BIN_PATH}" >&2
    exit 1
fi

echo "==> Assembling ${BUNDLE}…"
rm -rf "${BUNDLE}"
mkdir -p "${BUNDLE}/Contents/MacOS"
mkdir -p "${BUNDLE}/Contents/Resources"

cp "${BIN_PATH}" "${BUNDLE}/Contents/MacOS/${APP_NAME}"
cp Info.plist "${BUNDLE}/Contents/Info.plist"

# Bundle any WhisperKit Core ML resources that landed next to the binary.
BIN_DIR="$(dirname "${BIN_PATH}")"
shopt -s nullglob
for resource in "${BIN_DIR}"/*.bundle; do
    cp -R "${resource}" "${BUNDLE}/Contents/Resources/"
done
shopt -u nullglob

echo "==> Ad-hoc codesigning…"
codesign --force --deep --sign - "${BUNDLE}"

echo ""
echo "Built: $(pwd)/${BUNDLE}"
echo ""
echo "Next steps:"
echo "  1. mv ${BUNDLE} /Applications/"
echo "  2. Open /Applications/${BUNDLE} once (Right-click → Open the first time)."
echo "  3. System Settings → Privacy & Security → Accessibility → add Murmur."
echo "  4. System Settings → Privacy & Security → Microphone → enable Murmur."
echo "  5. Press ⌘⌥Space anywhere to dictate."
