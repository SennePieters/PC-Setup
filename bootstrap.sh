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
    echo "Select Interface:"
    echo "1) Terminal UI (Gum) - Keyboard driven"
    echo "2) Graphical UI (Zenity) - Mouse driven"
    read -r -p "Choice [1]: " UI_CHOICE < /dev/tty
    UI_CHOICE=${UI_CHOICE:-1}

    if [ "$UI_CHOICE" == "2" ]; then
        SCRIPT_NAME="main_gui.sh"
        # Check for Zenity
        if ! command -v zenity &> /dev/null; then
            echo "Zenity not found. Installing..."
            sudo pacman -S --noconfirm zenity < /dev/tty
        fi
    else
        SCRIPT_NAME="main.sh"
        # Check for Gum
        if ! command -v gum &> /dev/null; then
            echo "Gum not found. Installing..."
            if command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm gum < /dev/tty
            else
                echo "Warning: Package manager not supported. Please install 'gum' manually."
            fi
        fi
    fi

    # Hand off to the Linux GUI script
    TARGET="$TEMP_DIR/linux/$SCRIPT_NAME"
    mkdir -p "$(dirname "$TARGET")"
    
    echo "Downloading Linux setup script..."
    if [ -n "$GITHUB_TOKEN" ]; then
        curl -fsSL -H "Authorization: token $GITHUB_TOKEN" "$REPO_URL/linux/$SCRIPT_NAME" -o "$TARGET" < /dev/null
    else
        curl -fsSL "$REPO_URL/linux/$SCRIPT_NAME" -o "$TARGET" < /dev/null
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
