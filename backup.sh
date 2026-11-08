#!/usr/bin/env bash
set -e

PROJECT_DIR="$HOME/linux-ops-platform"
BACKUP_DIR="$HOME/backups"
DATE=$(date +%Y%m%d-%H%M%S)
ARCHIVE="$BACKUP_DIR/linux-ops-platform-$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"
tar --exclude='linux-ops-platform/.git' -czf "$ARCHIVE" -C "$HOME" linux-ops-platform
mapfile -t OLD_BACKUPS < <(ls -1t "$BACKUP_DIR"/linux-ops-platform-*.tar.gz 2>/dev/null | tail -n +8)
if ((${#OLD_BACKUPS[@]})); then
  printf '删除旧备份: %s\n' "${OLD_BACKUPS[@]}"
  rm -- "${OLD_BACKUPS[@]}"
fi
echo "备份完成：$ARCHIVE"
