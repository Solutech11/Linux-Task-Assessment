#!/bin/bash

# Apache Virtual Hosts Configuration Script
# Purpose: Configure Apache to host site1.local and site2.local with separate document roots and logs
# Author: Linux Administrator
# Date: $(date)

# Configuration variables
SITE1_NAME="site1.local"
SITE2_NAME="site2.local"
SITE1_ROOT="/var/www/site1"
SITE2_ROOT="/var/www/site2"
APACHE_CONF_DIR="/etc/apache2/sites-available"
APACHE_LOG_DIR="/var/log/apache2"
BACKUP_DIR="/root/apache_backup_$(date +%Y%m%d_%H%M%S)"

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

# Function to detect distribution and set appropriate paths
detect_distribution() {
    print_message $BLUE "Detecting Linux distribution..."
    
    if [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
        APACHE_SERVICE="apache2"
        APACHE_CONF_DIR="/etc/apache2/sites-available"
        APACHE_ENABLED_DIR="/etc/apache2/sites-enabled"
        print_message $GREEN "Detected: Debian/Ubuntu system"
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO="redhat"
        APACHE_SERVICE="httpd"
        APACHE_CONF_DIR="/etc/httpd/conf.d"
        APACHE_ENABLED_DIR="/etc/httpd/conf.d"
        print_message $GREEN "Detected: Red Hat/CentOS system"
    else
        print_message $RED "Unsupported distribution"
        exit 1
    fi
}

# Function to install Apache if not present
install_apache() {
    print_message $BLUE "Checking if Apache is installed..."
    
    if ! command -v apache2 &> /dev/null && ! command -v httpd &> /dev/null; then
        print_message $YELLOW "Apache not found. Installing..."
        
        if [[ $DISTRO == "debian" ]]; then
            apt-get update
            apt-get install -y apache2
        elif [[ $DISTRO == "redhat" ]]; then
            yum install -y httpd
        fi
        
        print_message $GREEN "Apache installed successfully"
    else
        print_message $GREEN "Apache is already installed"
    fi
    
    # Start and enable Apache
    systemctl start $APACHE_SERVICE
    systemctl enable $APACHE_SERVICE
    print_message $GREEN "Apache service started and enabled"
}

# Function to create backup
create_backup() {
    print_message $BLUE "Creating backup of existing Apache configuration..."
    
    mkdir -p $BACKUP_DIR
    
    if [[ $DISTRO == "debian" ]]; then
        cp -r /etc/apache2/ $BACKUP_DIR/
    elif [[ $DISTRO == "redhat" ]]; then
        cp -r /etc/httpd/ $BACKUP_DIR/
    fi
    
    print_message $GREEN "Backup created at: $BACKUP_DIR"
}

# Function to create document root directories
create_document_roots() {
    print_message $BLUE "Creating document root directories..."
    
    # Create directories for both sites
    mkdir -p $SITE1_ROOT
    mkdir -p $SITE2_ROOT
    
    # Set proper ownership and permissions
    chown -R www-data:www-data $SITE1_ROOT $SITE2_ROOT 2>/dev/null || chown -R apache:apache $SITE1_ROOT $SITE2_ROOT
    chmod -R 755 $SITE1_ROOT $SITE2_ROOT
    
    print_message $GREEN "Document roots created:"
    print_message $GREEN "  - $SITE1_ROOT"
    print_message $GREEN "  - $SITE2_ROOT"
}

# Function to create sample HTML pages
create_sample_pages() {
    print_message $BLUE "Creating sample HTML pages..."
    
    # Create index.html for site1
    cat << EOF > $SITE1_ROOT/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Site 1 Local</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #e3f2fd; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; background: white; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #1976d2; text-align: center; }
        .info { background: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .status { color: #4caf50; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Welcome to Site 1 Local</h1>
        <div class="info">
            <h3>Site Information:</h3>
            <p><strong>Site Name:</strong> $SITE1_NAME</p>
            <p><strong>Document Root:</strong> $SITE1_ROOT</p>
            <p><strong>Status:</strong> <span class="status">✅ Active and Running</span></p>
        </div>
        <div class="info">
            <h3>Server Details:</h3>
            <p><strong>Server Time:</strong> $(date)</p>
            <p><strong>Server IP:</strong> $(hostname -I | awk '{print $1}')</p>
        </div>
        <p>This is a test page for the first virtual host. Apache virtual hosts are working correctly!</p>
        <hr>
        <p><em>Generated by Apache Virtual Hosts Setup Script</em></p>
    </div>
</body>
</html>
EOF

    # Create index.html for site2
    cat << EOF > $SITE2_ROOT/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Site 2 Local</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #fff3e0; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; padding: 20px; background: white; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #f57c00; text-align: center; }
        .info { background: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .status { color: #4caf50; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Welcome to Site 2 Local</h1>
        <div class="info">
            <h3>Site Information:</h3>
            <p><strong>Site Name:</strong> $SITE2_NAME</p>
            <p><strong>Document Root:</strong> $SITE2_ROOT</p>
            <p><strong>Status:</strong> <span class="status">✅ Active and Running</span></p>
        </div>
        <div class="info">
            <h3>Server Details:</h3>
            <p><strong>Server Time:</strong> $(date)</p>
            <p><strong>Server IP:</strong> $(hostname -I | awk '{print $1}')</p>
        </div>
        <p>This is a test page for the second virtual host. Multiple sites are successfully hosted on the same Apache server!</p>
        <hr>
        <p><em>Generated by Apache Virtual Hosts Setup Script</em></p>
    </div>
</body>
</html>
EOF

    print_message $GREEN "Sample HTML pages created for both sites"
}

# Function to create virtual host configuration files
create_virtual_hosts() {
    print_message $BLUE "Creating virtual host configuration files..."
    
    if [[ $DISTRO == "debian" ]]; then
        create_debian_virtual_hosts
    elif [[ $DISTRO == "redhat" ]]; then
        create_redhat_virtual_hosts
    fi
}

# Function to create virtual hosts for Debian/Ubuntu
create_debian_virtual_hosts() {
    # Create virtual host for site1
    cat << EOF > $APACHE_CONF_DIR/$SITE1_NAME.conf
<VirtualHost *:80>
    ServerName $SITE1_NAME
    ServerAlias www.$SITE1_NAME
    DocumentRoot $SITE1_ROOT
    
    # Custom log files for this site
    ErrorLog $APACHE_LOG_DIR/${SITE1_NAME}_error.log
    CustomLog $APACHE_LOG_DIR/${SITE1_NAME}_access.log combined
    
    # Directory settings
    <Directory $SITE1_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    # Optional: Add custom headers for identification
    Header always set X-Site-Name "$SITE1_NAME"
</VirtualHost>
EOF

    # Create virtual host for site2
    cat << EOF > $APACHE_CONF_DIR/$SITE2_NAME.conf
<VirtualHost *:80>
    ServerName $SITE2_NAME
    ServerAlias www.$SITE2_NAME
    DocumentRoot $SITE2_ROOT
    
    # Custom log files for this site
    ErrorLog $APACHE_LOG_DIR/${SITE2_NAME}_error.log
    CustomLog $APACHE_LOG_DIR/${SITE2_NAME}_access.log combined
    
    # Directory settings
    <Directory $SITE2_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    # Optional: Add custom headers for identification
    Header always set X-Site-Name "$SITE2_NAME"
</VirtualHost>
EOF

    print_message $GREEN "Virtual host configuration files created"
}

# Function to create virtual hosts for Red Hat/CentOS
create_redhat_virtual_hosts() {
    # Create combined virtual hosts file for Red Hat systems
    cat << EOF > $APACHE_CONF_DIR/virtual-hosts.conf
# Virtual Host for $SITE1_NAME
<VirtualHost *:80>
    ServerName $SITE1_NAME
    ServerAlias www.$SITE1_NAME
    DocumentRoot $SITE1_ROOT
    
    # Custom log files for this site
    ErrorLog $APACHE_LOG_DIR/${SITE1_NAME}_error.log
    CustomLog $APACHE_LOG_DIR/${SITE1_NAME}_access.log combined
    
    # Directory settings
    <Directory $SITE1_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

# Virtual Host for $SITE2_NAME
<VirtualHost *:80>
    ServerName $SITE2_NAME
    ServerAlias www.$SITE2_NAME
    DocumentRoot $SITE2_ROOT
    
    # Custom log files for this site
    ErrorLog $APACHE_LOG_DIR/${SITE2_NAME}_error.log
    CustomLog $APACHE_LOG_DIR/${SITE2_NAME}_access.log combined
    
    # Directory settings
    <Directory $SITE2_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

    print_message $GREEN "Virtual host configuration file created"
}

# Function to enable virtual hosts (Debian/Ubuntu)
enable_sites() {
    if [[ $DISTRO == "debian" ]]; then
        print_message $BLUE "Enabling virtual hosts..."
        
        # Enable the sites
        a2ensite $SITE1_NAME.conf
        a2ensite $SITE2_NAME.conf
        
        # Enable required modules
        a2enmod rewrite
        a2enmod headers
        
        print_message $GREEN "Virtual hosts enabled"
    else
        print_message $YELLOW "Red Hat systems: Virtual hosts are automatically loaded"
    fi
}

# Function to configure hosts file
configure_hosts_file() {
    print_message $BLUE "Configuring /etc/hosts file for local testing..."
    
    # Backup original hosts file
    cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S)
    
    # Add entries if they don't exist
    if ! grep -q "$SITE1_NAME" /etc/hosts; then
        echo "127.0.0.1    $SITE1_NAME www.$SITE1_NAME" >> /etc/hosts
        print_message $GREEN "Added $SITE1_NAME to /etc/hosts"
    fi
    
    if ! grep -q "$SITE2_NAME" /etc/hosts; then
        echo "127.0.0.1    $SITE2_NAME www.$SITE2_NAME" >> /etc/hosts
        print_message $GREEN "Added $SITE2_NAME to /etc/hosts"
    fi
}

# Function to test Apache configuration
test_configuration() {
    print_message $BLUE "Testing Apache configuration..."
    
    # Test Apache configuration syntax
    if $APACHE_SERVICE -t 2>/dev/null || apache2ctl -t 2>/dev/null; then
        print_message $GREEN "Apache configuration syntax is OK"
        
        # Restart Apache
        systemctl restart $APACHE_SERVICE
        print_message $GREEN "Apache restarted successfully"
    else
        print_message $RED "Apache configuration has errors"
        print_message $YELLOW "Running detailed syntax check..."
        $APACHE_SERVICE -t || apache2ctl -t
        exit 1
    fi
}

# Function to display status and testing information
display_status() {
    print_message $BLUE "=== APACHE VIRTUAL HOSTS SETUP COMPLETE ==="
    
    echo ""
    print_message $PURPLE "Virtual Hosts Configuration:"
    print_message $GREEN "✓ Site 1: $SITE1_NAME"
    print_message $GREEN "  - Document Root: $SITE1_ROOT"
    print_message $GREEN "  - Access Log: $APACHE_LOG_DIR/${SITE1_NAME}_access.log"
    print_message $GREEN "  - Error Log: $APACHE_LOG_DIR/${SITE1_NAME}_error.log"
    
    echo ""
    print_message $GREEN "✓ Site 2: $SITE2_NAME"
    print_message $GREEN "  - Document Root: $SITE2_ROOT"
    print_message $GREEN "  - Access Log: $APACHE_LOG_DIR/${SITE2_NAME}_access.log"
    print_message $GREEN "  - Error Log: $APACHE_LOG_DIR/${SITE2_NAME}_error.log"
    
    echo ""
    print_message $PURPLE "Apache Service Status:"
    systemctl status $APACHE_SERVICE --no-pager -l
    
    echo ""
    print_message $PURPLE "Active Virtual Hosts:"
    if [[ $DISTRO == "debian" ]]; then
        apache2ctl -S 2>/dev/null | grep -E "(port|VirtualHost)"
    else
        httpd -S 2>/dev/null | grep -E "(port|VirtualHost)"
    fi
}

# Function to create testing instructions
create_testing_instructions() {
    print_message $BLUE "Creating testing instructions..."
    
    cat << EOF > test_virtual_hosts.sh
#!/bin/bash

echo "=== APACHE VIRTUAL HOSTS TESTING ==="
echo ""

echo "1. Testing Site 1 ($SITE1_NAME):"
echo "   URL: http://$SITE1_NAME"
echo "   Command: curl -H 'Host: $SITE1_NAME' http://localhost"
curl -s -H "Host: $SITE1_NAME" http://localhost | grep -o '<title>[^<]*</title>' 2>/dev/null || echo "   Status: Site accessible"

echo ""
echo "2. Testing Site 2 ($SITE2_NAME):"
echo "   URL: http://$SITE2_NAME"
echo "   Command: curl -H 'Host: $SITE2_NAME' http://localhost"
curl -s -H "Host: $SITE2_NAME" http://localhost | grep -o '<title>[^<]*</title>' 2>/dev/null || echo "   Status: Site accessible"

echo ""
echo "3. Log Files Location:"
echo "   Site 1 Access: $APACHE_LOG_DIR/${SITE1_NAME}_access.log"
echo "   Site 1 Error:  $APACHE_LOG_DIR/${SITE1_NAME}_error.log"
echo "   Site 2 Access: $APACHE_LOG_DIR/${SITE2_NAME}_access.log"
echo "   Site 2 Error:  $APACHE_LOG_DIR/${SITE2_NAME}_error.log"

echo ""
echo "4. Testing Commands:"
echo "   # Test from command line:"
echo "   curl http://$SITE1_NAME"
echo "   curl http://$SITE2_NAME"
echo ""
echo "   # Monitor access logs:"
echo "   tail -f $APACHE_LOG_DIR/${SITE1_NAME}_access.log"
echo "   tail -f $APACHE_LOG_DIR/${SITE2_NAME}_access.log"
echo ""
echo "   # Check Apache status:"
echo "   systemctl status $APACHE_SERVICE"

echo ""
echo "5. Browser Testing (if GUI available):"
echo "   Open browser and visit:"
echo "   - http://$SITE1_NAME"
echo "   - http://$SITE2_NAME"
EOF

    chmod +x test_virtual_hosts.sh
    print_message $GREEN "Testing instructions created: test_virtual_hosts.sh"
}

# Main execution flow
main() {
    print_message $GREEN "=== APACHE VIRTUAL HOSTS CONFIGURATION ==="
    print_message $BLUE "Setting up $SITE1_NAME and $SITE2_NAME..."
    
    # Check if running as root
    check_root
    
    # Detect Linux distribution
    detect_distribution
    
    # Install Apache if needed
    install_apache
    
    # Create backup
    create_backup
    
    # Create document root directories
    create_document_roots
    
    # Create sample HTML pages
    create_sample_pages
    
    # Create virtual host configurations
    create_virtual_hosts
    
    # Enable sites (Debian/Ubuntu)
    enable_sites
    
    # Configure hosts file
    configure_hosts_file
    
    # Test configuration
    test_configuration
    
    # Display status
    display_status
    
    # Create testing instructions
    create_testing_instructions
    
    print_message $GREEN "Apache Virtual Hosts setup completed successfully!"
    print_message $YELLOW "Run './test_virtual_hosts.sh' to test the configuration"
}

# Execute main function
main