#!/bin/bash
# Back up all local Authenticator data so it can be restored after testing.
# The keyring and database must stay in sync — always back up both together.

set -euo pipefail

BACKUP_DIR=~/.authenticator-backup-$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

# SQLite database (account/provider metadata)
if [ -d ~/.local/share/authenticator ]; then
    cp -a ~/.local/share/authenticator "$BACKUP_DIR/data"
fi

# oo7 file-backend keyring (TOTP secrets)
if [ -d ~/.local/share/keyrings ]; then
    cp -a ~/.local/share/keyrings "$BACKUP_DIR/keyrings"
fi

# Favicon cache
if [ -d ~/.cache/authenticator ]; then
    cp -a ~/.cache/authenticator "$BACKUP_DIR/cache"
fi

# GSettings via dconf
if command -v dconf >/dev/null 2>&1; then
    dconf dump /com/belmoussaoui/Authenticator/ > "$BACKUP_DIR/dconf.ini"
fi

echo "Backed up to $BACKUP_DIR"
