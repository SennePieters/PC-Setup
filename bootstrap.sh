#!/bin/bash

# Configuration: Set this to your raw repository URL
REPO_URL="https://raw.githubusercontent.com/YourUser/PC-Setup/main"

# Detect the Operating System
OS_TYPE=$(uname -s)

case "$OS_TYPE" in
    Linux*)     OS="Linux" ;;
    Darwin*)    OS="Mac" ;;
    CYGWIN*|MINGW*|MSYS*) OS="Windows" ;;
    *)          OS="UNKNOWN" ;;
esac

echo "Detected OS: $OS"

# Create a temporary directory for the session
TEMP_DIR=$(mktemp -d)

# Ensure cleanup of temporary files on exit
trap 'rm -rf "$TEMP_DIR"' EXIT

if [ "$OS" == "Linux" ]; then
    # Check for Gum (GUI dependency)
    if ! command -v gum &> /dev/null; then
        echo "Gum not found. Installing..."
        if command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm gum
        else
            echo "Warning: Package manager not supported. Please install 'gum' manually."
        fi
    fi

    # Hand off to the Linux GUI script
    TARGET="$TEMP_DIR/main.sh"
    
    echo "Downloading Linux setup script..."
    curl -fsSL "$REPO_URL/main.sh" -o "$TARGET"

    if [ -f "$TARGET" ]; then
        chmod +x "$TARGET"
        "$TARGET"
    else
        echo "Error: Failed to download main.sh from $REPO_URL"
        exit 1
    fi
elif [ "$OS" == "Windows" ]; then
    echo "Windows environment detected."
    echo "Downloading Windows setup script..."
    curl -fsSL "$REPO_URL/setup.ps1" -o "$TEMP_DIR/setup.ps1"
    powershell.exe -ExecutionPolicy Bypass -File "$(cygpath -w "$TEMP_DIR/setup.ps1")"
else
    echo "Unsupported Operating System: $OS_TYPE"
    exit 1
fi
