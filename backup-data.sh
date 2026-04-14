#!/bin/bash
# Back up all local Authenticator data so it can be restored after testing.
# Captures both the native (RPM/system) install and the Flatpak install.
# The keyring and database must stay in sync — always back up both together.

set -euo pipefail

FLATPAK_ID="com.belmoussaoui.Authenticator"
BACKUP_DIR=~/.authenticator-backup-$(date +%Y%m%d_%H%M%S)

NATIVE_DATA=~/.local/share/authenticator
NATIVE_CACHE=~/.cache/authenticator
FLATPAK_ROOT=~/.var/app/"${FLATPAK_ID}"
FLATPAK_DATA="${FLATPAK_ROOT}"/data/authenticator
FLATPAK_CACHE="${FLATPAK_ROOT}"/cache/authenticator
FLATPAK_CONFIG="${FLATPAK_ROOT}"/config

# The keyring lives on the host for both installs: the Flatpak app reaches it
# through the Secret Service portal rather than mounting it into the sandbox.
KEYRINGS=~/.local/share/keyrings

mkdir -p "${BACKUP_DIR}"/native "${BACKUP_DIR}"/flatpak

backed_up_any=0

# ---- Native (RPM / cargo install) ----
if [ -d "${NATIVE_DATA}" ]; then
    cp -a "${NATIVE_DATA}" "${BACKUP_DIR}"/native/data
    echo "Backed up native database"
    backed_up_any=1
fi

if [ -d "${NATIVE_CACHE}" ]; then
    cp -a "${NATIVE_CACHE}" "${BACKUP_DIR}"/native/cache
    echo "Backed up native favicon cache"
fi

if command -v dconf >/dev/null 2>&1; then
    dconf dump /com/belmoussaoui/Authenticator/ > "${BACKUP_DIR}"/native/dconf.ini
    echo "Backed up native GSettings"
fi

# ---- Flatpak ----
if [ -d "${FLATPAK_DATA}" ]; then
    cp -a "${FLATPAK_DATA}" "${BACKUP_DIR}"/flatpak/data
    echo "Backed up Flatpak database"
    backed_up_any=1
fi

if [ -d "${FLATPAK_CACHE}" ]; then
    cp -a "${FLATPAK_CACHE}" "${BACKUP_DIR}"/flatpak/cache
    echo "Backed up Flatpak favicon cache"
fi

# Flatpak keeps its own dconf database under config/; copy the whole config dir
# so whatever layout the runtime uses is preserved.
if [ -d "${FLATPAK_CONFIG}" ]; then
    cp -a "${FLATPAK_CONFIG}" "${BACKUP_DIR}"/flatpak/config
    echo "Backed up Flatpak config"
fi

# ---- Shared keyring ----
if [ -d "${KEYRINGS}" ]; then
    cp -a "${KEYRINGS}" "${BACKUP_DIR}"/keyrings
    echo "Backed up keyring (shared by native and Flatpak via portal)"
fi

if [ "${backed_up_any}" -eq 0 ]; then
    echo "Warning: no Authenticator data found in either native or Flatpak locations" >&2
fi

echo "Backed up to ${BACKUP_DIR}"
