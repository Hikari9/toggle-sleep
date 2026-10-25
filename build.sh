#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Toggle Sleep"
BUNDLE_NAME="${APP_NAME}.app"
BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/Applications"

echo "==> Building ${APP_NAME} with Xcode's Swift toolchain..."
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer" xcrun swiftc -O -target arm64-apple-macos13.0 "${BUILD_DIR}/main.swift" -o "${BUILD_DIR}/${APP_NAME}"

echo "==> Creating app bundle..."
rm -rf "${BUILD_DIR}/${BUNDLE_NAME}"
mkdir -p "${BUILD_DIR}/${BUNDLE_NAME}/Contents/MacOS"
mkdir -p "${BUILD_DIR}/${BUNDLE_NAME}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${BUILD_DIR}/${BUNDLE_NAME}/Contents/MacOS/${APP_NAME}"
cp "${BUILD_DIR}/Info.plist" "${BUILD_DIR}/${BUNDLE_NAME}/Contents/Info.plist"
cp "${BUILD_DIR}/AppIcon.icns" "${BUILD_DIR}/${BUNDLE_NAME}/Contents/Resources/AppIcon.icns"

echo "==> Ad-hoc signing bundle..."
codesign --force --deep --sign - "${BUILD_DIR}/${BUNDLE_NAME}"

echo "==> Installing to ${TARGET_DIR}/${BUNDLE_NAME}..."
mkdir -p "${TARGET_DIR}"
rm -rf "${TARGET_DIR}/Sleep Toggle.app" "${TARGET_DIR}/${BUNDLE_NAME}"
cp -R "${BUILD_DIR}/${BUNDLE_NAME}" "${TARGET_DIR}/${BUNDLE_NAME}"

echo "==> Done! Installed at: ${TARGET_DIR}/${BUNDLE_NAME}"
