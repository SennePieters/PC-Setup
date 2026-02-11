#!/bin/bash

# Configuration
REPO_URL="https://github.com/SennePieters/PC-Setup"
BRANCH="main"
REPO_NAME=$(basename "$REPO_URL")
ARCHIVE_URL="$REPO_URL/archive/$BRANCH.tar.gz"
ROOT_DIR_IN_ARCHIVE="$REPO_NAME-$BRANCH"

# Detect the Operating System
OS_TYPE=$(uname -s)

case "$OS_TYPE" in
    Linux*)     OS="Linux" ;;
    Darwin*)    OS="Mac" ;;
    CYGWIN*|MINGW*|MSYS*) OS="Windows" ;;
    *)          OS="UNKNOWN" ;;
esac

# Install Gum if not present
if ! command -v gum &> /dev/null; then
    echo "Gum not found. Installing..."
    if [ "$OS" == "Linux" ]; then
        sudo pacman -S --noconfirm gum < /dev/tty
    elif [ "$OS" == "Windows" ]; then
        winget.exe install charmbracelet.gum --accept-source-agreements --accept-package-agreements
    elif [ "$OS" == "Mac" ]; then
        if command -v brew &> /dev/null; then
            brew install gum
        fi
    fi
fi

gum style --foreground 212 "Detected OS: $OS"

# Detect if running from local source (Development Mode)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ -d "$SCRIPT_DIR/$OS" ]; then
    USE_LOCAL=true
    gum style --foreground 212 "Development mode: Using local files from $SCRIPT_DIR"
else
    USE_LOCAL=false
fi

# Create a temporary directory for the session
TEMP_DIR=$(mktemp -d)

# Ensure cleanup of temporary files on exit
trap 'rm -rf "$TEMP_DIR"' EXIT

if [ "$OS" == "Linux" ]; then
    SCRIPT_NAME="main.sh"

    if [ "$USE_LOCAL" = true ]; then
        gum style --foreground 212 "Copying local files..."
        cp -r "$SCRIPT_DIR/$OS" "$TEMP_DIR/"
        [ -d "$SCRIPT_DIR/settings" ] && cp -r "$SCRIPT_DIR/settings" "$TEMP_DIR/"
    else
        gum spin --spinner dot --title "Downloading setup files..." -- bash -c "curl -L '$ARCHIVE_URL' | tar -xz -C '$TEMP_DIR' --strip-components=1"
    fi

    # Run the script from the OS directory
    TARGET_DIR="$TEMP_DIR/$OS"
    if [ -d "$TARGET_DIR" ]; then
        (cd "$TARGET_DIR" && chmod +x "$SCRIPT_NAME" && ./"$SCRIPT_NAME")
    else
        gum style --foreground 196 "Error: $OS folder not found in download. It might not exist in the repository."
        exit 1
    fi
elif [ "$OS" == "Windows" ]; then
    SCRIPT_NAME="setup.ps1"
    gum style --foreground 212 "$OS environment detected."

    if [ "$USE_LOCAL" = true ]; then
        gum style --foreground 212 "Copying local files..."
        cp -r "$SCRIPT_DIR/$OS" "$TEMP_DIR/"
        [ -d "$SCRIPT_DIR/settings" ] && cp -r "$SCRIPT_DIR/settings" "$TEMP_DIR/"
    else
        gum spin --spinner dot --title "Downloading setup files..." -- bash -c "curl -L '$ARCHIVE_URL' | tar -xz -C '$TEMP_DIR' --strip-components=1"
    fi

    TARGET_DIR="$TEMP_DIR/$OS"
    if [ -d "$TARGET_DIR" ]; then
        powershell.exe -ExecutionPolicy Bypass -File "$(cygpath -w "$TARGET_DIR/$SCRIPT_NAME")"
    else
        gum style --foreground 196 "Error: $OS folder not found in download. It might not exist in the repository."
        exit 1
    fi
else
    echo "Unsupported Operating System: $OS_TYPE"
    exit 1
fi
