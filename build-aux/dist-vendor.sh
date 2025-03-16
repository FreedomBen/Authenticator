#!/bin/sh
export DIST="$1"
export SOURCE_ROOT="$2"

cd "$SOURCE_ROOT"
mkdir "$DIST"/.cargo
# cargo-vendor-filterer can be found at https://github.com/coreos/cargo-vendor-filterer
# It is also part of the Rust SDK extension.
cargo vendor-filterer --platform=x86_64-unknown-linux-gnu --platform=aarch64-unknown-linux-gnu > "$DIST"/.cargo/config
rm -f vendor/gettext-sys/gettext-*.tar.*
# remove the tarball from checksums
echo $(jq -c 'del(.files["gettext-0.22.5.tar.xz"])' vendor/gettext-sys/.cargo-checksum.json) > vendor/gettext-sys/.cargo-checksum.json
# Move vendor into dist tarball directory
mv vendor "$DIST"

