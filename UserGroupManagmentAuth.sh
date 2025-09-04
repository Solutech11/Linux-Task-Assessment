#!/bin/bash

# User & Group Management Automation Script
# Purpose: Create 5 users, add them to devteam group, set passwords, and force password change on first login
# Author: Linux Administrator
# Date: $(date)

# Script configuration
GROUP_NAME="devteam"
USERS=("dev1" "dev2" "dev3" "dev4" "dev5")
DEFAULT_PASSWORD="TempPass123!"

# Color codes for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_message $RED "Error: This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to create group if it doesn't exist
create_group() {
    print_message $BLUE "Checking if group '$GROUP_NAME' exists..."
    
    if getent group $GROUP_NAME > /dev/null 2>&1; then
        print_message $YELLOW "Group '$GROUP_NAME' already exists"
    else
        print_message $BLUE "Creating group '$GROUP_NAME'..."
        groupadd $GROUP_NAME
        if [[ $? -eq 0 ]]; then
            print_message $GREEN "Successfully created group '$GROUP_NAME'"
        else
            print_message $RED "Failed to create group '$GROUP_NAME'"
            exit 1
        fi
    fi
}

# Function to create users
create_users() {
    print_message $BLUE "Starting user creation process..."
    
    for user in "${USERS[@]}"; do
        print_message $BLUE "Processing user: $user"
        
        # Check if user already exists
        if id "$user" &>/dev/null; then
            print_message $YELLOW "User '$user' already exists, skipping creation"
        else
            # Create user with home directory
            useradd -m -s /bin/bash -G $GROUP_NAME "$user"
            if [[ $? -eq 0 ]]; then
                print_message $GREEN "Successfully created user '$user'"
            else
                print_message $RED "Failed to create user '$user'"
                continue
            fi
        fi
        
        # Set password for user
        print_message $BLUE "Setting password for user '$user'..."
        echo "$user:$DEFAULT_PASSWORD" | chpasswd
        if [[ $? -eq 0 ]]; then
            print_message $GREEN "Password set for user '$user'"
        else
            print_message $RED "Failed to set password for user '$user'"
        fi
        
        # Force password change on first login
        print_message $BLUE "Configuring password expiry for user '$user'..."
        chage -d 0 "$user"
        if [[ $? -eq 0 ]]; then
            print_message $GREEN "Password expiry configured for user '$user'"
        else
            print_message $RED "Failed to configure password expiry for user '$user'"
        fi
        
        # Ensure user is in the devteam group (in case user existed before)
        usermod -a -G $GROUP_NAME "$user"
        
        print_message $GREEN "User '$user' setup completed"
        echo "----------------------------------------"
    done
}

# Function to display summary
display_summary() {
    print_message $BLUE "=== SETUP SUMMARY ==="
    
    # Show group information
    print_message $BLUE "Group Information:"
    getent group $GROUP_NAME
    
    echo ""
    print_message $BLUE "User Information:"
    for user in "${USERS[@]}"; do
        if id "$user" &>/dev/null; then
            echo "User: $user"
            echo "  - Groups: $(groups $user | cut -d: -f2)"
            echo "  - Home Directory: $(getent passwd $user | cut -d: -f6)"
            echo "  - Shell: $(getent passwd $user | cut -d: -f7)"
            echo "  - Password Status: $(passwd -S $user 2>/dev/null | awk '{print $2}')"
            echo ""
        fi
    done
    
    print_message $GREEN "Script execution completed successfully!"
    print_message $YELLOW "Note: All users have been set with default password '$DEFAULT_PASSWORD'"
    print_message $YELLOW "Users will be forced to change password on first login"
}

# Function to create a cleanup script (optional)
create_cleanup_script() {
    cat << 'EOF' > cleanup_users.sh
#!/bin/bash
# Cleanup script to remove created users and group

USERS=("dev1" "dev2" "dev3" "dev4" "dev5")
GROUP_NAME="devteam"

echo "Removing users..."
for user in "${USERS[@]}"; do
    if id "$user" &>/dev/null; then
        userdel -r "$user"
        echo "Removed user: $user"
    fi
done

echo "Removing group..."
if getent group $GROUP_NAME > /dev/null 2>&1; then
    groupdel $GROUP_NAME
    echo "Removed group: $GROUP_NAME"
fi

echo "Cleanup completed!"
EOF
    
    chmod +x cleanup_users.sh
    print_message $GREEN "Cleanup script 'cleanup_users.sh' created"
}

# Main execution flow
main() {
    print_message $GREEN "=== User & Group Management Automation ==="
    print_message $BLUE "Starting script execution..."
    
    # Check if running as root
    check_root
    
    # Create group
    create_group
    
    # Create users
    create_users
    
    # Display summary
    display_summary
    
    # Create cleanup script
    read -p "Do you want to create a cleanup script? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_cleanup_script
    fi
    
    print_message $GREEN "All tasks completed successfully!"
}

# Execute main function
main