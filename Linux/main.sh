#!/bin/bash

# --- Helper Functions ---

refresh_sudo() {
    # Prompt for sudo password via GUI if needed
    if ! sudo -v; then
        if ! zenity --password --title="Sudo Authentication" | sudo -S -v; then
            zenity --error --text="Authentication failed or cancelled."
            exit 1
        fi
    fi
    # Keep sudo alive
    (while true; do sudo -v; sleep 60; done) &
    SUDO_PID=$!
    trap 'kill $SUDO_PID' EXIT
}

install_packages() {
    local pkgs=("$@")
    local to_install=()

    for pkg in "${pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -eq 0 ]; then
        zenity --info --text="All selected packages are already installed." --timeout=3
        return
    fi

    # Install with a pulsating progress bar
    (
        echo "# Installing: ${to_install[*]}"
        # Redirect output to prevent clutter, rely on exit code
        if paru -S --noconfirm "${to_install[@]}" > /dev/null 2>&1; then
            echo "100"
        else
            echo "fail"
            exit 1
        fi
    ) | zenity --progress --pulsate --title="Installing Packages" --text="Starting installation..." --auto-close

    if [ $? -eq 0 ]; then
        zenity --info --text="Successfully installed: ${to_install[*]}" --timeout=3
    else
        zenity --error --text="Failed to install one or more packages."
    fi
}

# --- Main Logic ---

refresh_sudo

# Ensure paru is installed
if ! command -v paru &> /dev/null; then
    ( echo "# Installing Paru..."; sudo pacman -S --noconfirm paru > /dev/null 2>&1 ) | \
    zenity --progress --pulsate --title="Setup" --text="Installing Paru..." --auto-close
fi

while true; do
    CHOICE=$(zenity --list --title="CachyOS Automation Tool" --text="Select an action:" \
        --column="Action" \
        "Install Core Apps" \
        "Gaming Setup" \
        "Dev Tools" \
        "System Tweaks" \
        "Dotfiles" \
        "Exit" \
        --height=350 --width=350)

    # Handle Cancel/Close
    if [ -z "$CHOICE" ] || [ "$CHOICE" == "Exit" ]; then
        break
    fi

    case "$CHOICE" in
        "Install Core Apps")
            APPS=$(zenity --list --checklist --title="Core Apps" --column="Install" --column="App" \
                FALSE "firefox" FALSE "discord" FALSE "spotify" FALSE "vlc" FALSE "obsidian" FALSE "thunar" \
                --separator=" ")
            [ -n "$APPS" ] && install_packages $APPS
            ;;
        "Gaming Setup")
            APPS=$(zenity --list --checklist --title="Gaming Setup" --column="Install" --column="App" \
                FALSE "steam" FALSE "lutris" FALSE "heroic-games-launcher-bin" FALSE "gamemode" FALSE "mangohud" FALSE "protonup-qt" \
                --separator=" ")
            [ -n "$APPS" ] && install_packages $APPS
            ;;
        "Dev Tools")
            APPS=$(zenity --list --checklist --title="Dev Tools" --column="Install" --column="App" \
                FALSE "visual-studio-code-bin" FALSE "git" FALSE "docker" FALSE "docker-compose" FALSE "neovim" FALSE "kitty" \
                --separator=" ")
            [ -n "$APPS" ] && install_packages $APPS
            ;;
        "Dotfiles")
            if zenity --question --text="Apply dotfiles using Stow?"; then
                ( echo "# Stowing..."; stow . ) | zenity --progress --pulsate --auto-close
            fi
            ;;
    esac
done
