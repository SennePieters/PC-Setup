#!/bin/bash
# Framework for Dotfiles (Hyprland, Waybar, etc.)
# Best practice: Use GNU Stow.
# Structure expected: ./dotfiles/{package}/...

DOTFILES_REPO="https://github.com/SennePieters/.dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

configure_de_customizations() {
    # Ensure Git is installed
    if ! command -v git &> /dev/null; then
        gum spin --spinner dot --title "Installing Git..." -- sudo pacman -S --noconfirm git
    fi

    # Clone or Update Dotfiles
    if [ ! -d "$DOTFILES_DIR" ]; then
        if gum confirm "Clone dotfiles to $DOTFILES_DIR?"; then
            gum spin --spinner dot --title "Cloning dotfiles..." -- git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        else
            gum style --foreground 196 "Skipping dotfiles setup."
            return 0
        fi
    else
        if gum confirm "Update dotfiles in $DOTFILES_DIR?"; then
            gum spin --spinner dot --title "Pulling updates..." -- git -C "$DOTFILES_DIR" pull
        fi
    fi

    if [ -z "$(ls -A "$DOTFILES_DIR")" ]; then
        gum style --foreground 212 "Dotfiles directory is empty."
        return 0
    fi

    # List directories in dotfiles to allow selection (exclude .git)
    local TARGETS=$(find "$DOTFILES_DIR" -mindepth 1 -maxdepth 1 -type d -not -name ".git" -exec basename {} \; 2>/dev/null)

    if [ -z "$TARGETS" ]; then
        gum style --foreground 212 "No configuration packages found in $DOTFILES_DIR."
        return 0
    fi

    DE_CUSTOMIZATIONS_SELECTED=$(echo "$TARGETS" | gum choose --no-limit --header "Select Configs to Stow")
}

install_de_customizations() {
    # Ensure stow is installed
    if ! command -v stow &> /dev/null; then
        gum spin --spinner dot --title "Installing GNU Stow..." -- sudo pacman -S --noconfirm stow
    fi

    if [ -n "$DE_CUSTOMIZATIONS_SELECTED" ]; then
        local SORTED_APPS=$(echo "$DE_CUSTOMIZATIONS_SELECTED" | grep -v "^hyprland$")
        if echo "$DE_CUSTOMIZATIONS_SELECTED" | grep -q "^hyprland$"; then
            SORTED_APPS="$SORTED_APPS hyprland"
        fi

        for app in $SORTED_APPS; do
            # Use --adopt to handle existing files by adopting them, then reset git to discard local changes
            if ! gum spin --spinner dot --title "Stowing $app..." -- stow --restow --adopt -d "$DOTFILES_DIR" -t "$HOME" "$app"; then
                gum style --foreground 196 "Stow failed for $app. Retrying to show error..."
                stow --restow --adopt -v -d "$DOTFILES_DIR" -t "$HOME" "$app"
            else
                git -C "$DOTFILES_DIR" restore "$app" &> /dev/null
            fi
        done
        gum style --foreground 76 "Configs applied."
    fi
}