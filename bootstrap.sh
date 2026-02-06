#!/bin/bash

# Configuration: Set this to your raw repository URL
REPO_URL="https://raw.githubusercontent.com/SennePieters/PC-Setup/main"

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
    TARGET="$TEMP_DIR/linux/main.sh"
    mkdir -p "$(dirname "$TARGET")"
    
    echo "Downloading Linux setup script..."
    if [ -n "$GITHUB_TOKEN" ]; then
        curl -fsSL -H "Authorization: token $GITHUB_TOKEN" "$REPO_URL/linux/main.sh" -o "$TARGET"
    else
        curl -fsSL "$REPO_URL/linux/main.sh" -o "$TARGET"
    fi

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
    mkdir -p "$TEMP_DIR/windows"
    if [ -n "$GITHUB_TOKEN" ]; then
        curl -fsSL -H "Authorization: token $GITHUB_TOKEN" "$REPO_URL/windows/setup.ps1" -o "$TEMP_DIR/windows/setup.ps1"
    else
        curl -fsSL "$REPO_URL/windows/setup.ps1" -o "$TEMP_DIR/windows/setup.ps1"
    fi
    powershell.exe -ExecutionPolicy Bypass -File "$(cygpath -w "$TEMP_DIR/windows/setup.ps1")"
else
    echo "Unsupported Operating System: $OS_TYPE"
    exit 1
fi
