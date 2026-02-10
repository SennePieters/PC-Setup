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

echo "Detected OS: $OS"

# Create a temporary directory for the session
TEMP_DIR=$(mktemp -d)

# Ensure cleanup of temporary files on exit
trap 'rm -rf "$TEMP_DIR"' EXIT

if [ "$OS" == "Linux" ]; then
    SCRIPT_NAME="main.sh"

    # Check for Gum (TUI dependency)
    if ! command -v gum &> /dev/null; then
        echo "Gum not found. Installing..."
        sudo pacman -S --noconfirm gum < /dev/tty
    fi

    echo "Downloading setup files..."
    # Download the archive and extract only the OS-specific and settings folders
    # Note: This still downloads the whole (small) archive but only extracts what's needed.
    curl -L "$ARCHIVE_URL" | tar -xz -C "$TEMP_DIR" --strip-components=1 \
        "$ROOT_DIR_IN_ARCHIVE/$OS" \
        "$ROOT_DIR_IN_ARCHIVE/settings"

    # Run the script from the OS directory
    TARGET_DIR="$TEMP_DIR/$OS"
    if [ -d "$TARGET_DIR" ]; then
        (cd "$TARGET_DIR" && chmod +x "$SCRIPT_NAME" && ./"$SCRIPT_NAME")
    else
        echo "Error: $OS folder not found in download. It might not exist in the repository."
        exit 1
    fi
elif [ "$OS" == "Windows" ]; then
    SCRIPT_NAME="setup.ps1"
    echo "$OS environment detected."

    echo "Downloading setup files..."
    # Download the archive and extract only the OS-specific and settings folders
    curl -L "$ARCHIVE_URL" | tar -xz -C "$TEMP_DIR" --strip-components=1 \
        "$ROOT_DIR_IN_ARCHIVE/$OS" \
        "$ROOT_DIR_IN_ARCHIVE/settings"

    TARGET_DIR="$TEMP_DIR/$OS"
    if [ -d "$TARGET_DIR" ]; then
        powershell.exe -ExecutionPolicy Bypass -File "$(cygpath -w "$TARGET_DIR/$SCRIPT_NAME")"
    else
        echo "Error: $OS folder not found in download. It might not exist in the repository."
        exit 1
    fi
else
    echo "Unsupported Operating System: $OS_TYPE"
    exit 1
fi
