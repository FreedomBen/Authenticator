#!/bin/bash
# Restore Authenticator data from a backup created by backup-data.sh.
# Usage: ./restore-data.sh [<backup-directory> [<source>] [<destination>]]
#   source/destination: native | flatpak
# Missing arguments are prompted for interactively.

set -euo pipefail

FLATPAK_ID="com.belmoussaoui.Authenticator"

NATIVE_DATA=~/.local/share/authenticator
NATIVE_CACHE=~/.cache/authenticator
FLATPAK_ROOT=~/.var/app/"${FLATPAK_ID}"
FLATPAK_DATA="${FLATPAK_ROOT}"/data/authenticator
FLATPAK_CACHE="${FLATPAK_ROOT}"/cache/authenticator
FLATPAK_CONFIG="${FLATPAK_ROOT}"/config

KEYRINGS=~/.local/share/keyrings

usage() {
    echo "Usage: $0 [<backup-directory> [<source>] [<destination>]]"
    echo "  source/destination: native | flatpak"
    echo ""
    echo "Available backups:"
    ls -d ~/.authenticator-backup-* 2>/dev/null || echo "  (none)"
}

prompt_choice() {
    local label="$1"
    local choice=""
    while [ "${choice}" != "native" ] && [ "${choice}" != "flatpak" ]; do
        read -r -p "${label} [native/flatpak]: " choice
    done
    echo "${choice}"
}

BACKUP_DIR="${1:-}"
if [ -z "${BACKUP_DIR}" ]; then
    usage
    echo ""
    read -r -p "Backup directory: " BACKUP_DIR
fi

if [ ! -d "${BACKUP_DIR}" ]; then
    echo "Error: backup directory '${BACKUP_DIR}' does not exist" >&2
    exit 1
fi

SOURCE="${2:-}"
if [ -z "${SOURCE}" ]; then
    SOURCE=$(prompt_choice "Restore from which install")
fi

DEST="${3:-}"
if [ -z "${DEST}" ]; then
    DEST=$(prompt_choice "Restore into which install")
fi

case "${SOURCE}" in
    native|flatpak) ;;
    *) echo "Error: source must be 'native' or 'flatpak'" >&2; exit 1 ;;
esac
case "${DEST}" in
    native|flatpak) ;;
    *) echo "Error: destination must be 'native' or 'flatpak'" >&2; exit 1 ;;
esac

SRC_DIR="${BACKUP_DIR}/${SOURCE}"
if [ ! -d "${SRC_DIR}" ]; then
    echo "Error: backup does not contain a '${SOURCE}' subdirectory (${SRC_DIR})" >&2
    exit 1
fi

echo "Restoring from ${SOURCE} -> ${DEST}"

# Pick destination paths based on chosen target install.
if [ "${DEST}" = "native" ]; then
    DEST_DATA="${NATIVE_DATA}"
    DEST_CACHE="${NATIVE_CACHE}"
else
    DEST_DATA="${FLATPAK_DATA}"
    DEST_CACHE="${FLATPAK_CACHE}"
    mkdir -p "${FLATPAK_ROOT}"/data "${FLATPAK_ROOT}"/cache
fi

# ---- Database ----
if [ -d "${SRC_DIR}/data" ]; then
    rm -rf "${DEST_DATA}"
    mkdir -p "$(dirname "${DEST_DATA}")"
    cp -a "${SRC_DIR}/data" "${DEST_DATA}"
    echo "Restored database -> ${DEST_DATA}"
fi

# ---- Favicon cache ----
if [ -d "${SRC_DIR}/cache" ]; then
    rm -rf "${DEST_CACHE}"
    mkdir -p "$(dirname "${DEST_CACHE}")"
    cp -a "${SRC_DIR}/cache" "${DEST_CACHE}"
    echo "Restored favicon cache -> ${DEST_CACHE}"
fi

# ---- GSettings / dconf ----
# Native uses the host dconf database; Flatpak has its own under config/.
if [ "${DEST}" = "native" ]; then
    if [ -f "${SRC_DIR}/dconf.ini" ] && command -v dconf >/dev/null 2>&1; then
        dconf load /com/belmoussaoui/Authenticator/ < "${SRC_DIR}/dconf.ini"
        echo "Restored GSettings via dconf"
    elif [ -d "${BACKUP_DIR}/flatpak/config" ] && [ "${SOURCE}" = "flatpak" ] && command -v dconf >/dev/null 2>&1; then
        echo "Note: source backup is Flatpak; no portable dconf.ini available to import into native." >&2
    fi
else
    # Flatpak destination: prefer the flatpak config tree if present in the
    # source, otherwise fall back to importing the native dconf.ini via
    # `flatpak run --command=dconf`.
    if [ -d "${SRC_DIR}/config" ]; then
        rm -rf "${FLATPAK_CONFIG}"
        cp -a "${SRC_DIR}/config" "${FLATPAK_CONFIG}"
        echo "Restored Flatpak config -> ${FLATPAK_CONFIG}"
    elif [ -f "${SRC_DIR}/dconf.ini" ] && command -v flatpak >/dev/null 2>&1; then
        if flatpak info "${FLATPAK_ID}" >/dev/null 2>&1; then
            flatpak run --command=dconf "${FLATPAK_ID}" \
                load /com/belmoussaoui/Authenticator/ < "${SRC_DIR}/dconf.ini"
            echo "Restored GSettings into Flatpak via 'flatpak run dconf'"
        else
            echo "Note: Flatpak '${FLATPAK_ID}' is not installed; skipping dconf import." >&2
        fi
    fi
fi

# ---- Shared keyring ----
# Both installs share the host keyring via the Secret Service portal.
if [ -d "${BACKUP_DIR}/keyrings" ]; then
    rm -rf "${KEYRINGS}"
    cp -a "${BACKUP_DIR}/keyrings" "${KEYRINGS}"
    echo "Restored keyring"
fi

echo "Restored from ${BACKUP_DIR} (${SOURCE} -> ${DEST})"
