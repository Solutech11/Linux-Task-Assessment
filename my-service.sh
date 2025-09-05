#!/bin/bash

# Simple service script
LOG_FILE="/var/log/my-service.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Function to log messages
log_message() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

# Main service loop
log_message "Service started"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    log_message "Service is running - $(uptime)"
    sleep 60  # Wait 60 seconds
done