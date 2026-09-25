#!/bin/bash
set -euo pipefail

# Builds the Rust FFI library locally and packages AirliftFFI.xcframework.
# The privileged/exploit implementation is intentionally not included here.

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}"
export IPHONEOS_DEPLOYMENT_TARGET="${IPHONEOS_DEPLOYMENT_TARGET:-27.0}"

source "$HOME/.cargo/env" 2>/dev/null || true

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT/rust-core"

if [ ! -f Cargo.toml ]; then
  echo "error: rust-core/Cargo.toml is missing"
  exit 1
fi

rustup target add aarch64-apple-ios aarch64-apple-ios-sim 2>/dev/null || true

cargo build --release --target aarch64-apple-ios
cargo build --release --target aarch64-apple-ios-sim

cd "$ROOT"

rm -rf "$ROOT/AirliftFFI.xcframework"

xcodebuild -create-xcframework   -library rust-core/target/aarch64-apple-ios/release/libairlift_ffi.a   -headers rust-core/include   -library rust-core/target/aarch64-apple-ios-sim/release/libairlift_ffi.a   -headers rust-core/include   -output "$ROOT/AirliftFFI.xcframework"

echo "AirliftFFI.xcframework generated."
