#!/bin/bash
# Verysync macOS Installer
# Downloads and installs Verysync from https://github.com/chancejiang/verysync
# Supports macOS arm64 (Apple Silicon) architecture

set -e

# Default values
VERSION="v2.21.3"
INSTALL_DIR="/Applications"
FORCE=false
CHECK_UPDATE=false
REMOVE=false
PROXY=""
LOCAL_FILE=""

# Function to show help
show_help() {
    cat << EOF
Usage: $0 [-h] [-c] [--remove] [-p proxy] [-f] [--version vx.y.z] [-l file]

Options:
  -h, --help            Show this help message
  -p, --proxy           Set proxy server (e.g., -p socks5://127.0.0.1:1080 or -p http://127.0.0.1:3128)
  -f, --force           Force installation
      --version         Install specific version (default: $VERSION)
  -l, --local           Install from a local file (absolute path required)
      --remove          Uninstall Verysync
  -c, --check           Check for updates
EOF
    exit 0
}

# Function to check architecture
check_architecture() {
    ARCH=$(uname -m)
    case "$ARCH" in
        arm64)
            ARCH="arm64"
            ;;
        *)
            echo "Unsupported architecture: $ARCH"
            echo "Only arm64 (Apple Silicon) is supported"
            exit 1
            ;;
    esac
    echo "Detected architecture: $ARCH"
}

# Function to download Verysync
download_verysync() {
    DOWNLOAD_URL="https://github.com/chancejiang/verysync/releases/download/$VERSION/verysync-macos-$ARCH.tar.gz"
    echo "Downloading Verysync $VERSION for macOS $ARCH..."
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
    # Extract the tarball
    echo "Extracting Verysync..."
    tar -xzf /tmp/verysync.tar.gz -C /tmp/
    
    # Copy to Applications folder
    echo "Installing Verysync.app to Applications folder..."
    if [[ -d "$INSTALL_DIR/verysync.app" && "$FORCE" = false ]]; then
        echo "Error: Verysync.app is already installed in $INSTALL_DIR"
        echo "Use -f or --force to reinstall"
        rm -rf /tmp/verysync.tar.gz /tmp/verysync-macos-$ARCH
        exit 1
    fi
    
    # Remove existing if force
    if [[ -d "$INSTALL_DIR/verysync.app" && "$FORCE" = true ]]; then
        echo "Removing existing Verysync.app..."
        rm -rf "$INSTALL_DIR/verysync.app"
    fi
    
    cp -r /tmp/verysync-macos-$ARCH/verysync.app "$INSTALL_DIR/"
    
    # Install launchd service
    echo "Installing launchd service..."
    cp -r /tmp/verysync-macos-$ARCH/etc/macos-launchd/verysync.plist ~/Library/LaunchAgents/
    
    # Load the service
    launchctl load ~/Library/LaunchAgents/verysync.plist
    
    # Cleanup
    rm -rf /tmp/verysync.tar.gz /tmp/verysync-macos-$ARCH
    
    echo "Verysync installation completed successfully!"
    echo "The Verysync.app has been installed to your Applications folder"
    echo "Access the web interface at http://localhost:8886"
}

# Function to uninstall Verysync
uninstall_verysync() {
    echo "Uninstalling Verysync..."
    
    # Unload and remove launchd service
    if launchctl list | grep -q verysync; then
        launchctl unload ~/Library/LaunchAgents/verysync.plist
    fi
    rm -f ~/Library/LaunchAgents/verysync.plist
    
    # Remove the app
    if [[ -d "$INSTALL_DIR/verysync.app" ]]; then
        rm -rf "$INSTALL_DIR/verysync.app"
    fi
    
    # Remove configuration
    rm -rf ~/.config/verysync
    
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
