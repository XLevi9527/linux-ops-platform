#!/usr/bin/env bash
set -e

PROJECT_DIR="$HOME/linux-ops-platform"
BACKUP_DIR="$HOME/backups"
DATE=$(date +%Y%m%d-%H%M%S)
ARCHIVE="$BACKUP_DIR/linux-ops-platform-$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"
tar --exclude='linux-ops-platform/.git' -czf "$ARCHIVE" -C "$HOME" linux-ops-platform

echo "备份完成：$ARCHIVE"
