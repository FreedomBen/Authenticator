#!/usr/bin/env bash
set -euo pipefail

GNOME_SDK_VERSION="48"
FREEDESKTOP_SDK_BRANCH="24.08"
MANIFEST="build-aux/com.belmoussaoui.Authenticator.Devel.json"

# Install required flatpak runtimes and extensions if missing
echo "Ensuring flatpak dependencies are installed..."
flatpak install --user --noninteractive flathub \
    org.gnome.Sdk//"${GNOME_SDK_VERSION}" \
    org.gnome.Platform//"${GNOME_SDK_VERSION}" \
    org.freedesktop.Sdk.Extension.rust-stable//"${FREEDESKTOP_SDK_BRANCH}" \
    org.freedesktop.Sdk.Extension.llvm20//"${FREEDESKTOP_SDK_BRANCH}" \
    || true

# The checked-in manifest targets runtime-version "master" (GNOME nightly).
# Create a temporary copy targeting the stable SDK instead.
STABLE_MANIFEST="build-aux/.Devel.stable.json"
trap 'rm -f "$STABLE_MANIFEST"' EXIT
sed 's/"runtime-version": "master"/"runtime-version": "'"${GNOME_SDK_VERSION}"'"/' \
    "$MANIFEST" > "$STABLE_MANIFEST"

# Build without installing
flatpak-builder --force-clean --repo=_flatpak_repo _flatpak "$STABLE_MANIFEST"

# Bundle
flatpak build-bundle _flatpak_repo Authenticator.flatpak \
    com.belmoussaoui.Authenticator.Devel

echo "Done! Built Authenticator.flatpak"

# To install:
#   flatpak --user install Authenticator.flatpak
# To run:
#   flatpak run com.belmoussaoui.Authenticator.Devel
