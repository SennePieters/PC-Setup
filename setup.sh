#!/bin/bash
# Install Gum if not present (for the GUI feel)
if ! command -v gum &> /dev/null; then
    sudo pacman -S --noconfirm gum
fi

# Define Actions
CHOICE=$(gum choose --no-limit "Update System" "Install Gaming Apps" "Config Dotfiles" "Optimize Kernel")

# Logic
for ITEM in $CHOICE; do
    case $ITEM in
        "Update System")
            gum spin --spinner dot --title "Updating..." -- sudo pacman -Syu --noconfirm
            ;;
        "Install Gaming Apps")
            paru -S --noconfirm steam lutris heroic-games-launcher-bin
            ;;
        "Config Dotfiles")
            # Pull your private config
            git clone https://oauth2:${GITHUB_TOKEN}@github.com/YourUser/private-config.git
            stow private-config
            ;;
    esac
done