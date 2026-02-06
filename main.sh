#!/bin/bash

# --- Configuration & Styles ---
BORDER_STYLE="gum style --foreground 212 --border-foreground 212 --border double --align center --width 50 --margin '1 2' --padding '2 4'"
ERROR_STYLE="gum style --foreground 196 --bold"
SUCCESS_STYLE="gum style --foreground 76 --bold"

# --- Helper Functions ---

# Refresh sudo credentials upfront to prevent spinner interruptions
refresh_sudo() {
    if ! sudo -v; then
        echo "Sudo privileges are required."
        exit 1
    fi
    # Keep sudo alive in background
    (while true; do sudo -v; sleep 60; done) &
    SUDO_PID=$!
    trap 'kill $SUDO_PID' EXIT
}

install_packages() {
    local pkgs=("$@")
    local to_install=()

    # Check if packages are already installed
    for pkg in "${pkgs[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -eq 0 ]; then
        echo "All selected packages are already installed."
        return
    fi

    # Install using paru (handles both Repo and AUR)
    if gum spin --spinner dot --title "Installing: ${to_install[*]}..." -- \
        paru -S --noconfirm "${to_install[@]}"; then
        $SUCCESS_STYLE "Successfully installed: ${to_install[*]}"
    else
        $ERROR_STYLE "Failed to install one or more packages."
    fi
}

check_cachyos_kernel() {
    # Check for AVX2 support (x86-64-v3) which is common for modern gaming CPUs
    if lscpu | grep -q "avx2"; then
        if ! pacman -Qi linux-cachyos-v3 &> /dev/null; then
            if gum confirm "AVX2 (v3) CPU detected. Install optimized 'linux-cachyos-v3'?"; then
                install_packages "linux-cachyos-v3" "linux-cachyos-v3-headers"
            fi
        else
            echo "Optimized kernel (v3) is already installed."
        fi
    elif lscpu | grep -q "avx512"; then
         # Check for v4 (AVX512)
         if gum confirm "AVX512 detected. Install optimized 'linux-cachyos-v4'?"; then
             install_packages "linux-cachyos-v4" "linux-cachyos-v4-headers"
         fi
    else
        echo "No specific CachyOS kernel optimization detected for this hardware."
    fi
}

# --- Main Logic ---

refresh_sudo

# Ensure paru is installed (CachyOS usually has it, but just in case)
if ! command -v paru &> /dev/null; then
    gum spin --title "Installing Paru..." -- sudo pacman -S --noconfirm paru
fi

while true; do
    clear
    echo "$($BORDER_STYLE 'CachyOS Automation Tool')"
    
    CHOICE=$(gum choose "Install Core Apps" "Gaming Setup" "Dev Tools" "System Tweaks" "Dotfiles" "Exit")
    
    case "$CHOICE" in
        "Install Core Apps")
            APPS=$(gum choose --no-limit "firefox" "discord" "spotify" "vlc" "obsidian" "thunar")
            [ -n "$APPS" ] && install_packages $APPS
            ;;
        "Gaming Setup")
            APPS=$(gum choose --no-limit "steam" "lutris" "heroic-games-launcher-bin" "gamemode" "mangohud" "protonup-qt")
            [ -n "$APPS" ] && install_packages $APPS
            ;;
        "Dev Tools")
            APPS=$(gum choose --no-limit "visual-studio-code-bin" "git" "docker" "docker-compose" "neovim" "kitty")
            [ -n "$APPS" ] && install_packages $APPS
            ;;
        "System Tweaks")
            check_cachyos_kernel
            ;;
        "Dotfiles")
            if gum confirm "Apply dotfiles using Stow?"; then
                # Assumes the repo structure allows 'stow .' or specific folders
                gum spin --spinner minidot --title "Stowing config..." -- stow .
                $SUCCESS_STYLE "Dotfiles applied!"
            fi
            ;;
        "Exit")
            echo "Goodbye!"
            break
            ;;
    esac
    
    echo ""
    gum style --faint "Press any key to continue..."
    read -n 1 -s
done
