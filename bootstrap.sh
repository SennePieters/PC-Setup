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
    SCRIPT_NAME="main.sh"

    # Check for Zenity (GUI dependency)
    if ! command -v zenity &> /dev/null; then
        echo "Zenity not found. Installing..."
        sudo pacman -S --noconfirm zenity < /dev/tty
    fi

    # Hand off to the Linux GUI script
    TARGET="$TEMP_DIR/$OS/$SCRIPT_NAME"
    mkdir -p "$(dirname "$TARGET")"
    
    echo "Downloading $OS setup script..."
    if [ -n "$GITHUB_TOKEN" ]; then
        curl -fsSL -H "Authorization: token $GITHUB_TOKEN" "$REPO_URL/$OS/$SCRIPT_NAME" -o "$TARGET" < /dev/null
    else
        curl -fsSL "$REPO_URL/$OS/$SCRIPT_NAME" -o "$TARGET" < /dev/null
    fi

    if [ -f "$TARGET" ]; then
        chmod +x "$TARGET"
        "$TARGET"
    else
        echo "Error: Failed to download main.sh from $REPO_URL"
        exit 1
    fi
elif [ "$OS" == "Windows" ]; then
    echo "$OS environment detected."
    echo "Downloading $OS setup script..."
    mkdir -p "$TEMP_DIR/$OS"
    if [ -n "$GITHUB_TOKEN" ]; then
        curl -fsSL -H "Authorization: token $GITHUB_TOKEN" "$REPO_URL/$OS/setup.ps1" -o "$TEMP_DIR/$OS/setup.ps1"
    else
        curl -fsSL "$REPO_URL/$OS/setup.ps1" -o "$TEMP_DIR/$OS/setup.ps1"
    fi
    powershell.exe -ExecutionPolicy Bypass -File "$(cygpath -w "$TEMP_DIR/$OS/setup.ps1")"
else
    echo "Unsupported Operating System: $OS_TYPE"
    exit 1
fi
