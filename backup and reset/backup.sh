#!/bin/bash

# Backup script for /var/www/html
SOURCE_DIR="/var/www/html"
BACKUP_DIR="/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/www_backup_${TIMESTAMP}.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create compressed backup
echo "Starting backup of $SOURCE_DIR..."
tar -czf "$BACKUP_FILE" -C /var/www html

# Check if backup was successful
if [ $? -eq 0 ]; then
    echo "Backup completed successfully: $BACKUP_FILE"
    echo "Backup size: $(du -sh $BACKUP_FILE | cut -f1)"
else
    echo "Backup failed!"
    exit 1
fi