#!/bin/bash
# Framework for Dotfiles (Hyprland, Waybar, etc.)
# Best practice: Use GNU Stow.
# Structure expected: ./dotfiles/{package}/...

configure_de_customizations() {
    local CONFIGS_DIR="../settings"

    if [ ! -d "$CONFIGS_DIR" ] || [ -z "$(ls -A "$CONFIGS_DIR")" ]; then
        gum style --foreground 212 "Settings directory not found or is empty. (Expected at ../settings)"
        return 0
    fi

    # List directories in dotfiles to allow selection
    local TARGETS=$(find "$CONFIGS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null)

    if [ -z "$TARGETS" ]; then
        gum style --foreground 212 "No configuration directories found in $CONFIGS_DIR."
        return 0
    fi

    DE_CUSTOMIZATIONS_SELECTED=$(echo "$TARGETS" | gum choose --no-limit --header "Select Configs to Stow")
}

install_de_customizations() {
    local CONFIGS_DIR="../settings"
    if [ -n "$DE_CUSTOMIZATIONS_SELECTED" ]; then
        for app in $DE_CUSTOMIZATIONS_SELECTED; do
            gum spin --spinner dot --title "Stowing $app..." -- stow -d "$CONFIGS_DIR" -t "$HOME" "$app"
        done
        gum style --foreground 76 "Configs applied."
    fi
}