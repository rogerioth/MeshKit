#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_DIR="${ROOT_DIR}/.build/xcodebuild"
SAMPLE_PROJECT="${ROOT_DIR}/Examples/MeshKitSample/MeshKitSample.xcodeproj"

build_package() {
    local name="$1"
    local destination="$2"

    echo "==> Building MeshKit package for ${name}"
    xcodebuild \
        -scheme MeshKit \
        -destination "${destination}" \
        -derivedDataPath "${DERIVED_DATA_DIR}/package-${name}" \
        build
}

build_sample() {
    local name="$1"
    local destination="$2"

    echo "==> Building MeshKitSample for ${name}"
    xcodebuild \
        -project "${SAMPLE_PROJECT}" \
        -scheme MeshKitSample \
        -destination "${destination}" \
        -derivedDataPath "${DERIVED_DATA_DIR}/sample-${name}" \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY="" \
        build
}

echo "==> Building MeshKit with SwiftPM"
swift build

echo "==> Generating MeshKitSample.xcodeproj"
ruby "${ROOT_DIR}/scripts/generate-sample-project.rb"

build_package "macos" "generic/platform=macOS"
build_package "ios-simulator" "generic/platform=iOS Simulator"
build_package "mac-catalyst" "generic/platform=macOS,variant=Mac Catalyst"

build_sample "macos" "generic/platform=macOS"
build_sample "ios-simulator" "generic/platform=iOS Simulator"
build_sample "mac-catalyst" "generic/platform=macOS,variant=Mac Catalyst"
