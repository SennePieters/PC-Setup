#!/bin/bash
# Framework for Dotfiles (Hyprland, Waybar, etc.)
# Best practice: Use GNU Stow.
# Structure expected: ./dotfiles/{package}/...

DOTFILES_REPO="https://github.com/SennePieters/.dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

configure_workspaces() {
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

    if gum confirm "Install & Configure GNOME Keyring (PAM)?"; then
        SETUP_KEYRING=true
    else
        SETUP_KEYRING=false
    fi
}

install_workspaces() {
    # Install packages from packages.txt if present
    local IFS=$' \t\n'
    local PKG_FILE="workspaces/hyprland.txt"
    if [ -f "$PKG_FILE" ]; then
        gum style --foreground 212 "Installing DE packages..."
        PACKAGES=$(cat "$PKG_FILE" | sed 's/\r//g' | grep -vE '^\s*#|^\s*$' | awk '{$1=$1};1' | tr '\n' ' ')
        if [ -n "$PACKAGES" ]; then
            # Use `yes` to auto-confirm any prompts that --noconfirm might miss
            if ! yes | paru -S --noconfirm --skipreview --needed $PACKAGES; then
                gum style --foreground 212 "Batch install failed. Attempting to install packages individually..."
                for package in $PACKAGES; do
                    yes | paru -S --noconfirm --skipreview --needed "$package" || gum style --foreground 196 "--> Failed to install '$package', skipping."
                done
            fi
        fi
    fi

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
            # 1. Use --adopt for plain files and --override='.*' for symlinks
            if ! gum spin --spinner dot --title "Stowing $app..." -- stow --restow --adopt --override='.*' -d "$DOTFILES_DIR" -t "$HOME" "$app"; then
                gum style --foreground 196 "Stow encountered an issue for $app. Showing details..."
                # Run verbosely so the user can see the exact conflict
                stow --restow --adopt --override='.*' -v -d "$DOTFILES_DIR" -t "$HOME" "$app"
            fi
            
            # 2. ALWAYS run git restore, regardless of whether stow succeeded or failed
            # This guarantees that the repo version of the file is what ends up in your $HOME
            git -C "$DOTFILES_DIR" restore "$app" &> /dev/null
            git -C "$DOTFILES_DIR" clean -fd "$app" &> /dev/null
            
        done
        gum style --foreground 76 "Configs applied."
    fi

    if [ "$SETUP_KEYRING" = true ]; then
        gum style --foreground 212 "Installing GNOME Keyring..."
        yes | paru -S --noconfirm --skipreview --needed gnome-keyring

        gum style --foreground 212 "Configuring PAM for auto-unlock..."

        # Refresh sudo credentials before editing system files
        sudo -v

        inject_pam_config() {
            local FILE="$1"
            local TYPE="$2"
            local LINE="$3"

            if [ ! -f "$FILE" ]; then
                gum style --foreground 196 "Warning: $FILE not found. Skipping."
                return
            fi

            if grep -qF "$LINE" "$FILE"; then
                gum style --foreground 240 "  -> $FILE already configured for $TYPE."
                return
            fi

            gum style --foreground 212 "  -> Injecting $TYPE into $FILE..."
            
            local TEMP_FILE=$(mktemp)
            awk -v type="$TYPE" -v line="$LINE" '
                { buffer[NR] = $0 }
                $1 == type { last_match = NR }
                END {
                    if (last_match == 0) last_match = NR
                    for (i = 1; i <= NR; i++) {
                        print buffer[i]
                        if (i == last_match) print line
                    }
                }
            ' "$FILE" > "$TEMP_FILE"
            sudo tee "$FILE" < "$TEMP_FILE" > /dev/null
            rm "$TEMP_FILE"
        }

        inject_pam_config "/etc/pam.d/sddm" "auth" "auth optional pam_gnome_keyring.so"
        inject_pam_config "/etc/pam.d/sddm" "session" "session optional pam_gnome_keyring.so auto_start"
        inject_pam_config "/etc/pam.d/login" "auth" "auth optional pam_gnome_keyring.so"
        inject_pam_config "/etc/pam.d/login" "session" "session optional pam_gnome_keyring.so auto_start"
        
        gum style --foreground 76 "GNOME Keyring setup complete."
    fi
}