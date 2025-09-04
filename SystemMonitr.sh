#!/bin/bash

# Complete System Monitoring Setup and Execution Script
# Description: Sets up system monitoring OR runs monitoring based on parameter
# Usage: 
#   ./script.sh setup    - Sets up monitoring system and cron job
#   ./script.sh monitor  - Runs monitoring (used by cron)
#   ./script.sh          - Interactive setup

# Configuration
SCRIPT_PATH="/usr/local/bin/system_monitor.sh"
LOG_FILE="/var/log/sys_health.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to log with timestamp
log_with_timestamp() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

# Function to get CPU usage
get_cpu_usage() {
    # Method 1: Using top command
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' 2>/dev/null)
    
    # Method 2: Using /proc/stat for more accuracy if top fails
    if [ -z "$CPU_USAGE" ] || [ "$CPU_USAGE" = "0.0" ]; then
        # Get CPU usage from /proc/stat
        cpu_line=$(head -n1 /proc/stat)
        cpu_times=($cpu_line)
        idle_time=${cpu_times[4]}
        total_time=0
        for time in "${cpu_times[@]:1:7}"; do
            total_time=$((total_time + time))
        done
        cpu_usage=$((100 * (total_time - idle_time) / total_time))
        CPU_USAGE="$cpu_usage.0"
    fi
    
    echo "$CPU_USAGE"
}

# Function to get Memory usage
get_memory_usage() {
    # Get memory info from /proc/meminfo
    TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    AVAILABLE_MEM=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    
    # If MemAvailable is not available, calculate it
    if [ -z "$AVAILABLE_MEM" ]; then
        FREE_MEM=$(grep MemFree /proc/meminfo | awk '{print $2}')
        CACHED_MEM=$(grep '^Cached:' /proc/meminfo | awk '{print $2}')
        AVAILABLE_MEM=$((FREE_MEM + CACHED_MEM))
    fi
    
    # Calculate used memory percentage
    USED_MEM=$((TOTAL_MEM - AVAILABLE_MEM))
    MEM_PERCENTAGE=$(awk "BEGIN {printf \"%.1f\", ($USED_MEM/$TOTAL_MEM)*100}")
    
    # Convert to human readable format
    TOTAL_MEM_GB=$(awk "BEGIN {printf \"%.1f\", $TOTAL_MEM/1024/1024}")
    USED_MEM_GB=$(awk "BEGIN {printf \"%.1f\", $USED_MEM/1024/1024}")
    
    echo "${MEM_PERCENTAGE}% (${USED_MEM_GB}GB/${TOTAL_MEM_GB}GB)"
}

# Function to get Disk usage
get_disk_usage() {
    # Get disk usage for root filesystem
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5 " (" $3 "/" $2 ")"}')
    echo "$DISK_USAGE"
}

# Function to create monitoring log entry
create_log_entry() {
    CPU=$(get_cpu_usage)
    MEMORY=$(get_memory_usage)
    DISK=$(get_disk_usage)
    
    # Create log entry
    log_with_timestamp "========================================="
    log_with_timestamp "SYSTEM HEALTH REPORT"
    log_with_timestamp "CPU Usage: ${CPU}%"
    log_with_timestamp "Memory Usage: $MEMORY"
    log_with_timestamp "Disk Usage: $DISK"
    log_with_timestamp "Hostname: $(hostname)"
    log_with_timestamp "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    log_with_timestamp "========================================="
    echo "" >> "$LOG_FILE"
}

# Function to run monitoring (called by cron)
run_monitoring() {
    # Check if log file exists, if not create it
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        chmod 644 "$LOG_FILE"
        log_with_timestamp "System monitoring log initialized"
        echo "" >> "$LOG_FILE"
    fi
    
    # Check if we can write to log file
    if [ ! -w "$LOG_FILE" ]; then
        echo "Error: Cannot write to $LOG_FILE. Please run as root or check permissions."
        exit 1
    fi
    
    # Create log entry
    create_log_entry
    
    # Optional: Rotate log file if it gets too large (>10MB)
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt 10485760 ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        touch "$LOG_FILE"
        chmod 644 "$LOG_FILE"
        log_with_timestamp "Log file rotated due to size limit"
        echo "Log file rotated due to size (>10MB)"
    fi
    
    exit 0
}

# Function to create the monitoring script
create_monitoring_script() {
    print_status "Creating monitoring script at $SCRIPT_PATH"
    
    # Create the script directory if it doesn't exist
    mkdir -p /usr/local/bin
    
    # Copy this script to the system location
    cp "$0" "$SCRIPT_PATH"
    
    # Make it executable
    chmod +x "$SCRIPT_PATH"
    chown root:root "$SCRIPT_PATH"
    
    print_status "Monitoring script created and configured"
}

# Function to setup log file
setup_log_file() {
    print_status "Setting up log file at $LOG_FILE"
    
    # Create log file
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    chown root:root "$LOG_FILE"
    
    # Initialize log
    echo "[$TIMESTAMP] System monitoring initialized" >> "$LOG_FILE"
    
    print_status "Log file created and initialized"
}

# Function to setup cron job
setup_cron_job() {
    print_status "Setting up cron job to run every 5 minutes"
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
        print_warning "Cron job already exists, skipping..."
        return
    fi
    
    # Add cron job
    (crontab -l 2>/dev/null; echo "*/5 * * * * $SCRIPT_PATH monitor >/dev/null 2>&1") | crontab -
    
    print_status "Cron job added successfully"
}

# Function to setup log rotation
setup_log_rotation() {
    print_status "Setting up log rotation"
    
    cat > /etc/logrotate.d/sys_health << EOF
/var/log/sys_health.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF
    
    print_status "Log rotation configured"
}

# Function to test the setup
test_setup() {
    print_status "Testing the monitoring system..."
    
    # Test script execution
    "$SCRIPT_PATH" monitor
    
    # Check if log entry was created
    if [ -s "$LOG_FILE" ]; then
        print_status "✓ Monitoring test successful!"
        echo ""
        echo "Recent log entries:"
        echo "==================="
        tail -10 "$LOG_FILE"
        echo ""
    else
        print_error "✗ Monitoring test failed!"
        return 1
    fi
}

# Function to show status
show_status() {
    print_header "SYSTEM MONITORING STATUS"
    
    # Check script file
    if [ -f "$SCRIPT_PATH" ]; then
        print_status "✓ Monitoring script: $SCRIPT_PATH"
        ls -la "$SCRIPT_PATH"
    else
        print_error "✗ Monitoring script not found"
    fi
    
    echo ""
    
    # Check log file
    if [ -f "$LOG_FILE" ]; then
        print_status "✓ Log file: $LOG_FILE"
        ls -la "$LOG_FILE"
        echo "Log file size: $(du -h $LOG_FILE | cut -f1)"
    else
        print_error "✗ Log file not found"
    fi
    
    echo ""
    
    # Check cron job
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
        print_status "✓ Cron job configured:"
        crontab -l | grep "$SCRIPT_PATH"
    else
        print_error "✗ Cron job not found"
    fi
    
    echo ""
    
    # Show recent logs
    if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
        print_status "Recent monitoring data:"
        echo "======================="
        tail -20 "$LOG_FILE"
    fi
}

# Function to perform complete setup
complete_setup() {
    print_header "SYSTEM MONITORING SETUP"
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root (use sudo)"
        exit 1
    fi
    
    echo "This script will set up system monitoring with the following:"
    echo "• CPU, Memory, and Disk usage monitoring"
    echo "• Logging every 5 minutes to $LOG_FILE"
    echo "• Automatic log rotation"
    echo ""
    
    # Create monitoring script
    create_monitoring_script
    
    # Setup log file
    setup_log_file
    
    # Setup cron job
    setup_cron_job
    
    # Setup log rotation
    setup_log_rotation
    
    # Test the setup
    test_setup
    
    echo ""
    print_header "SETUP COMPLETE"
    print_status "System monitoring is now active!"
    print_status "Logs will be written to: $LOG_FILE"
    print_status "Monitoring runs every 5 minutes"
    echo ""
    print_status "To view logs in real-time: sudo tail -f $LOG_FILE"
    print_status "To check status: $0 status"
    print_status "To view recent logs: $0 logs"
}

# Function to show recent logs
show_logs() {
    if [ -f "$LOG_FILE" ]; then
        print_header "RECENT SYSTEM MONITORING LOGS"
        tail -50 "$LOG_FILE"
    else
        print_error "Log file not found: $LOG_FILE"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  setup     - Complete setup of system monitoring"
    echo "  monitor   - Run monitoring (used by cron job)"
    echo "  status    - Show monitoring system status"
    echo "  logs      - Show recent monitoring logs"
    echo "  test      - Test monitoring functionality"
    echo "  help      - Show this help message"
    echo ""
    echo "If no option is provided, interactive setup will begin."
}

# Main execution logic
case "${1:-}" in
    "setup")
        complete_setup
        ;;
    "monitor")
        run_monitoring
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "test")
        if [ "$EUID" -ne 0 ]; then
            print_error "Please run as root (use sudo)"
            exit 1
        fi
        test_setup
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    "")
        # Interactive mode
        print_header "SYSTEM MONITORING INTERACTIVE SETUP"
        echo "This will set up automated system monitoring."
        echo -n "Do you want to proceed? (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            complete_setup
        else
            echo "Setup cancelled."
            exit 0
        fi
        ;;
    *)
        print_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac

exit 0