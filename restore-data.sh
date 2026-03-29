#!/bin/bash
# Restore Authenticator data from a backup created by backup-data.sh.
# Usage: ./restore-data.sh ~/.authenticator-backup-XXXXXXXX_XXXXXX

set -euo pipefail

BACKUP_DIR="${1:-}"
if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
    echo "Usage: $0 <backup-directory>"
    echo ""
    echo "Available backups:"
    ls -d ~/.authenticator-backup-* 2>/dev/null || echo "  (none)"
    exit 1
fi

if [ -d "$BACKUP_DIR/data" ]; then
    rm -rf ~/.local/share/authenticator
    cp -a "$BACKUP_DIR/data" ~/.local/share/authenticator
    echo "Restored database"
fi

if [ -d "$BACKUP_DIR/keyrings" ]; then
    rm -rf ~/.local/share/keyrings
    cp -a "$BACKUP_DIR/keyrings" ~/.local/share/keyrings
    echo "Restored keyring"
fi

if [ -d "$BACKUP_DIR/cache" ]; then
    rm -rf ~/.cache/authenticator
    cp -a "$BACKUP_DIR/cache" ~/.cache/authenticator
    echo "Restored favicon cache"
fi

if [ -f "$BACKUP_DIR/dconf.ini" ] && command -v dconf >/dev/null 2>&1; then
    dconf load /com/belmoussaoui/Authenticator/ < "$BACKUP_DIR/dconf.ini"
    echo "Restored GSettings"
fi

echo "Restored from $BACKUP_DIR"
