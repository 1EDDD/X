# Rust FFI build

This directory contains the Rust source used to build the iOS FFI library.

Run from the repository root:

    ./build-ios.sh

The script produces:

    AirliftFFI.xcframework/

The generated static libraries are intentionally not committed to Git. This keeps large build artifacts out of the repository.

The source tree must contain a Cargo project and its public headers under `include/`.
