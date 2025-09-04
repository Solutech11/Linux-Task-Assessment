#!/bin/bash

# File Permissions & ACLs Project Setup Script
# Purpose: Create shared directory with specific permissions and ACLs
# Author: Linux Administrator
# Date: $(date)

# Script configuration
SHARED_DIR="/shared_data"
GROUP_NAME="devteam"
READONLY_USER="observer"
TEST_USERS=("dev1" "dev2" "dev3")

# Color codes for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

# Function to check if ACL is supported
check_acl_support() {
    print_message $BLUE "Checking ACL support..."
    
    # Check if ACL tools are installed
    if ! command -v setfacl &> /dev/null || ! command -v getfacl &> /dev/null; then
        print_message $YELLOW "ACL tools not found. Installing..."
        
        # Detect distribution and install ACL
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y acl
        elif command -v yum &> /dev/null; then
            yum install -y acl
        elif command -v dnf &> /dev/null; then
            dnf install -y acl
        else
            print_message $RED "Could not install ACL tools. Please install manually."
            exit 1
        fi
    fi
    
    print_message $GREEN "ACL tools are available"
}

# Function to create the shared directory
create_shared_directory() {
    print_message $BLUE "Creating shared directory: $SHARED_DIR"
    
    # Create directory if it doesn't exist
    if [[ ! -d $SHARED_DIR ]]; then
        mkdir -p $SHARED_DIR
        print_message $GREEN "Directory $SHARED_DIR created"
    else
        print_message $YELLOW "Directory $SHARED_DIR already exists"
    fi
    
    # Set ownership to root and group
    chown root:$GROUP_NAME $SHARED_DIR
    print_message $GREEN "Ownership set to root:$GROUP_NAME"
}

# Function to set basic permissions
set_basic_permissions() {
    print_message $BLUE "Setting basic permissions on $SHARED_DIR"
    
    # Set permissions: owner(rwx), group(rwx), others(---)
    # The sticky bit (+t) prevents users from deleting others' files
    chmod 2770 $SHARED_DIR
    chmod +t $SHARED_DIR
    
    print_message $GREEN "Basic permissions set: drwxrws--T"
    print_message $YELLOW "Sticky bit enabled - users cannot delete others' files"
}

# Function to create readonly user
create_readonly_user() {
    print_message $BLUE "Creating readonly user: $READONLY_USER"
    
    if id "$READONLY_USER" &>/dev/null; then
        print_message $YELLOW "User '$READONLY_USER' already exists"
    else
        useradd -m -s /bin/bash "$READONLY_USER"
        echo "$READONLY_USER:ReadOnly123!" | chpasswd
        chage -d 0 "$READONLY_USER"
        print_message $GREEN "User '$READONLY_USER' created"
    fi
}

# Function to set ACLs
set_acls() {
    print_message $BLUE "Setting Access Control Lists (ACLs)..."
    
    # Set default ACLs for the directory
    # This ensures new files inherit the correct permissions
    setfacl -d -m g:$GROUP_NAME:rwx $SHARED_DIR
    setfacl -d -m o::--- $SHARED_DIR
    
    # Grant read-only access to the observer user
    setfacl -m u:$READONLY_USER:rx $SHARED_DIR
    setfacl -d -m u:$READONLY_USER:r-- $SHARED_DIR
    
    print_message $GREEN "Default ACLs set for group members (rwx)"
    print_message $GREEN "ACL set for $READONLY_USER (read-only access)"
}

# Function to create test files
create_test_files() {
    print_message $BLUE "Creating test files for demonstration..."
    
    # Create test files as different users
    for user in "${TEST_USERS[@]}"; do
        if id "$user" &>/dev/null; then
            # Create a test file as each user
            sudo -u $user bash -c "echo 'Test file created by $user' > $SHARED_DIR/test_$user.txt"
            print_message $GREEN "Created test file: test_$user.txt"
        fi
    done
    
    # Create a shared document
    echo "This is a shared document that all group members can edit" > $SHARED_DIR/shared_document.txt
    chown root:$GROUP_NAME $SHARED_DIR/shared_document.txt
    chmod 664 $SHARED_DIR/shared_document.txt
    print_message $GREEN "Created shared document: shared_document.txt"
}

# Function to display permissions and ACLs
display_permissions() {
    print_message $BLUE "=== DIRECTORY PERMISSIONS & ACL SUMMARY ==="
    
    echo ""
    print_message $PURPLE "Directory Permissions:"
    ls -ld $SHARED_DIR
    
    echo ""
    print_message $PURPLE "Directory ACLs:"
    getfacl $SHARED_DIR
    
    echo ""
    print_message $PURPLE "Files in Directory:"
    ls -la $SHARED_DIR
    
    if [[ -f "$SHARED_DIR/shared_document.txt" ]]; then
        echo ""
        print_message $PURPLE "Sample File ACLs:"
        getfacl $SHARED_DIR/shared_document.txt
    fi
}

# Function to create test scenarios
create_test_scenarios() {
    print_message $BLUE "Creating test scenario scripts..."
    
    # Test script for group members
    cat << 'EOF' > test_group_access.sh
#!/bin/bash
# Test script for group members

SHARED_DIR="/shared_data"
echo "=== Testing Group Member Access ==="

echo "1. Creating a file as current user..."
echo "File created by $(whoami)" > $SHARED_DIR/my_test_file.txt

echo "2. Listing directory contents..."
ls -la $SHARED_DIR

echo "3. Reading shared document..."
cat $SHARED_DIR/shared_document.txt 2>/dev/null || echo "Cannot read shared document"

echo "4. Attempting to delete another user's file..."
rm $SHARED_DIR/test_dev1.txt 2>/dev/null && echo "File deleted successfully" || echo "Cannot delete other user's file (expected due to sticky bit)"

echo "Test completed!"
EOF

    # Test script for readonly user
    cat << 'EOF' > test_readonly_access.sh
#!/bin/bash
# Test script for readonly user

SHARED_DIR="/shared_data"
echo "=== Testing Read-Only User Access ==="

echo "1. Listing directory contents..."
ls -la $SHARED_DIR

echo "2. Reading shared document..."
cat $SHARED_DIR/shared_document.txt 2>/dev/null || echo "Cannot read shared document"

echo "3. Attempting to create a file..."
echo "Test" > $SHARED_DIR/readonly_test.txt 2>/dev/null && echo "File created (unexpected!)" || echo "Cannot create file (expected)"

echo "4. Attempting to delete a file..."
rm $SHARED_DIR/test_dev1.txt 2>/dev/null && echo "File deleted (unexpected!)" || echo "Cannot delete file (expected)"

echo "Read-only test completed!"
EOF

    chmod +x test_group_access.sh test_readonly_access.sh
    print_message $GREEN "Test scripts created: test_group_access.sh and test_readonly_access.sh"
}

# Function to show usage instructions
show_usage_instructions() {
    print_message $BLUE "=== USAGE INSTRUCTIONS ==="
    
    echo ""
    print_message $YELLOW "Testing Group Member Access:"
    echo "  # Switch to a group member (e.g., dev1)"
    echo "  sudo su - dev1"
    echo "  # Run the test script"
    echo "  sudo /path/to/test_group_access.sh"
    
    echo ""
    print_message $YELLOW "Testing Read-Only Access:"
    echo "  # Switch to readonly user"
    echo "  sudo su - $READONLY_USER"
    echo "  # Run the test script"
    echo "  sudo /path/to/test_readonly_access.sh"
    
    echo ""
    print_message $YELLOW "Manual Testing Commands:"
    echo "  # Check ACLs: getfacl $SHARED_DIR"
    echo "  # Check permissions: ls -ld $SHARED_DIR"
    echo "  # Test file creation: touch $SHARED_DIR/test.txt"
    echo "  # Test file deletion: rm $SHARED_DIR/test.txt"
    
    echo ""
    print_message $YELLOW "Key Features Implemented:"
    echo "  ✓ Shared directory: $SHARED_DIR"
    echo "  ✓ Group members can read/write"
    echo "  ✓ Sticky bit prevents deleting others' files"
    echo "  ✓ ACL grants read-only access to $READONLY_USER"
    echo "  ✓ Default ACLs for new files"
}

# Main execution flow
main() {
    print_message $GREEN "=== File Permissions & ACLs Project Setup ==="
    print_message $BLUE "Starting setup process..."
    
    # Check if running as root
    check_root
    
    # Check ACL support
    check_acl_support
    
    # Create shared directory
    create_shared_directory
    
    # Set basic permissions
    set_basic_permissions
    
    # Create readonly user
    create_readonly_user
    
    # Set ACLs
    set_acls
    
    # Create test files
    create_test_files
    
    # Display permissions summary
    display_permissions
    
    # Create test scenarios
    create_test_scenarios
    
    # Show usage instructions
    show_usage_instructions
    
    print_message $GREEN "File Permissions & ACLs project setup completed successfully!"
}

# Execute main function
main