#!/usr/bin/env bash


# Build and install
#flatpak-builder --user --install --force-clean _flatpak build-aux/com.belmoussaoui.Authenticator.Devel.json

# Build without installing
flatpak-builder --force-clean --repo=_flatpak_repo _flatpak \
    build-aux/com.belmoussaoui.Authenticator.Devel.json

flatpak build-bundle _flatpak_repo Authenticator.flatpak \
        com.belmoussaoui.Authenticator.Devel
