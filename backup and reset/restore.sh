#!/bin/bash

# Restore script for /var/www/html
BACKUP_DIR="/backup"
RESTORE_DIR="/var/www"

# Check if backup file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_filename>"
    echo "Available backups:"
    ls -1 "$BACKUP_DIR"/www_backup_*.tar.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$BACKUP_DIR/$1"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file $BACKUP_FILE not found!"
    exit 1
fi

# Create backup of current data before restore
CURRENT_BACKUP="/tmp/current_www_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$CURRENT_BACKUP" -C /var/www html
echo "Current data backed up to: $CURRENT_BACKUP"

# Restore from backup
echo "Restoring from: $BACKUP_FILE"
rm -rf /var/www/html/*
tar -xzf "$BACKUP_FILE" -C /var/www

echo "Restore completed successfully!"