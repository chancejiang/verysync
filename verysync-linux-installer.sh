#!/bin/bash
# Verysync Linux Installer
# Downloads and installs Verysync from https://github.com/chancejiang/verysync
# Supports Linux amd64 and arm64 architectures

set -e

# Default values
VERSION="v2.21.3"
INSTALL_DIR="/usr/bin/verysync"
USER="root"
INDEX_LOCATION="$HOME/.config/verysync"
FORCE=false
CHECK_UPDATE=false
REMOVE=false
PROXY=""
LOCAL_FILE=""

# Function to show help
show_help() {
    cat << EOF
Usage: $0 [-h] [-c] [--remove] [-p proxy] [-f] [--version vx.y.z] [-l file] [-d index location] [-u user]

Options:
  -h, --help            Show this help message
  -p, --proxy           Set proxy server (e.g., -p socks5://127.0.0.1:1080 or -p http://127.0.0.1:3128)
  -f, --force           Force installation
      --version         Install specific version (default: $VERSION)
  -l, --local           Install from a local file (absolute path required)
      --remove          Uninstall Verysync
  -c, --check           Check for updates
  -d  --home            Set Verysync index location (default: ~/.config/verysync)
  -u  --user            Set user to run Verysync service (default: root)
EOF
    exit 0
}

# Function to check architecture
check_architecture() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        *)
            echo "Unsupported architecture: $ARCH"
            echo "Only amd64 and arm64 are supported"
            exit 1
            ;;
    esac
    echo "Detected architecture: $ARCH"
}

# Function to download Verysync
download_verysync() {
    DOWNLOAD_URL="https://github.com/chancejiang/verysync/releases/download/$VERSION/verysync-linux-$ARCH.tar.gz"
    echo "Downloading Verysync $VERSION for Linux $ARCH..."
    curl -L -x "$PROXY" -o /tmp/verysync.tar.gz "$DOWNLOAD_URL" || wget -e use_proxy=yes -e http_proxy="$PROXY" -O /tmp/verysync.tar.gz "$DOWNLOAD_URL"
}

# Function to install from local file
install_from_local() {
    echo "Installing from local file: $LOCAL_FILE"
    if [[ ! -f "$LOCAL_FILE" ]]; then
        echo "Error: Local file $LOCAL_FILE not found"
        exit 1
    fi
    cp "$LOCAL_FILE" /tmp/verysync.tar.gz
}

# Function to install Verysync
install_verysync() {
    # Create installation directory
    sudo mkdir -p "$INSTALL_DIR"
    
    # Extract the tarball
    echo "Extracting Verysync..."
    sudo tar -xzf /tmp/verysync.tar.gz -C /tmp/
    
    # Copy the binary
    echo "Installing Verysync binary..."
    sudo cp /tmp/verysync-linux-$ARCH/verysync "$INSTALL_DIR/"
    
    # Copy service files
    echo "Installing service files..."
    if [[ -d /tmp/verysync-linux-$ARCH/etc ]]; then
        # Systemd service
        sudo cp /tmp/verysync-linux-$ARCH/etc/linux-systemd/system/verysync@.service /etc/systemd/system/
        sudo cp /tmp/verysync-linux-$ARCH/etc/linux-systemd/system/verysync-resume.service /etc/systemd/system/
        
        # Init.d service
        sudo cp /tmp/verysync-linux-$ARCH/etc/linux-init.d/verysync /etc/init.d/
        sudo chmod +x /etc/init.d/verysync
        
        # Runit service
        sudo mkdir -p /etc/sv/verysync
        sudo cp -r /tmp/verysync-linux-$ARCH/etc/linux-runit/ /etc/sv/verysync/
    fi
    
    # Cleanup
    rm -rf /tmp/verysync.tar.gz /tmp/verysync-linux-$ARCH
    
    # Create systemd service for the specified user
    echo "Configuring systemd service for user $USER..."
    sudo systemctl daemon-reload
    sudo systemctl enable verysync@$USER
    sudo systemctl start verysync@$USER
    
    echo "Verysync installation completed successfully!"
    echo "Access the web interface at http://localhost:8886"
}

# Function to uninstall Verysync
uninstall_verysync() {
    echo "Uninstalling Verysync..."
    
    # Stop and disable service
    if systemctl is-active --quiet verysync@$USER; then
        sudo systemctl stop verysync@$USER
        sudo systemctl disable verysync@$USER
    fi
    
    # Remove binary
    sudo rm -rf "$INSTALL_DIR"
    
    # Remove service files
    sudo rm -f /etc/systemd/system/verysync@.service /etc/systemd/system/verysync-resume.service
    sudo rm -f /etc/init.d/verysync
    sudo rm -rf /etc/sv/verysync
    
    # Remove index location
    if [[ -d "$INDEX_LOCATION" ]]; then
        sudo rm -rf "$INDEX_LOCATION"
    fi
    
    # Cleanup
    sudo systemctl daemon-reload
    
    echo "Verysync uninstallation completed successfully!"
}

# Function to check for updates
check_update() {
    echo "Checking for updates..."
    LATEST_VERSION=$(curl -s https://api.github.com/repos/chancejiang/verysync/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    echo "Current version: $VERSION"
    echo "Latest version: $LATEST_VERSION"
    
    if [[ "$LATEST_VERSION" != "$VERSION" ]]; then
        echo "Update available!"
        echo "Run the installer with --version $LATEST_VERSION to update"
    else
        echo "You are already running the latest version"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        -p|--proxy)
            PROXY="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift 1
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        -l|--local)
            LOCAL_FILE="$2"
            shift 2
            ;;
        --remove)
            REMOVE=true
            shift 1
            ;;
        -c|--check)
            CHECK_UPDATE=true
            shift 1
            ;;
        -d|--home)
            INDEX_LOCATION="$2"
            shift 2
            ;;
        -u|--user)
            USER="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown option '$1'"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
if [[ "$CHECK_UPDATE" = true ]]; then
    check_update
    exit 0
fi

if [[ "$REMOVE" = true ]]; then
    uninstall_verysync
    exit 0
fi

# Check if already installed
if [[ -d "$INSTALL_DIR" && "$FORCE" = false ]]; then
    echo "Verysync is already installed at $INSTALL_DIR"
    echo "Use -f or --force to reinstall"
    exit 1
fi

# Check architecture
check_architecture

# Download or use local file
if [[ -n "$LOCAL_FILE" ]]; then
    install_from_local
else
    download_verysync
fi

# Install
install_verysync
