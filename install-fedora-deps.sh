#!/bin/bash
# Install Fedora build dependencies for Authenticator
# See DEVELOPING.md for full details

set -euo pipefail

echo "Installing native build dependencies..."
sudo dnf install -y \
    gtk4-devel \
    libadwaita-devel \
    gstreamer1-devel \
    gstreamer1-plugins-base-devel

echo "Installing build tools..."
sudo dnf install -y \
    meson \
    ninja-build \
    rpm-build

echo "Done! You can now run 'make build' to build the project."
