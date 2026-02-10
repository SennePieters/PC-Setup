#!/bin/bash

# --- Helper Functions ---

REPO_URL="https://raw.githubusercontent.com/SennePieters/PC-Setup/main"
PACKAGES_FILE="packages.txt"

refresh_sudo() {
    # Prompt for sudo password via GUI if needed
    if ! sudo -v; then
        if ! gum input --password --placeholder "Sudo Password" | sudo -S -v; then
            gum style --foreground 196 "Authentication failed or cancelled."
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
        gum style --foreground 212 "All selected packages are already installed."
        return
    fi

    # Install with a spinner
    if gum spin --spinner dot --title "Installing: ${to_install[*]}" -- paru -S --noconfirm "${to_install[@]}"; then
        gum style --foreground 76 "Successfully installed: ${to_install[*]}"
    else
        gum style --foreground 196 "Failed to install one or more packages."
    fi
}

ensure_dependencies() {
    # Ensure packages.txt exists for the app selection
    if [ ! -f "$PACKAGES_FILE" ]; then
        gum spin --spinner dot --title "Downloading package list..." -- \
            curl -fsSL "$REPO_URL/Linux/$PACKAGES_FILE" -o "$PACKAGES_FILE" 2>/dev/null
    fi
}

setup_configs() {
    # Framework for Dotfiles (Hyprland, Waybar, etc.)
    # Best practice: Use GNU Stow.
    # Structure expected: ./dotfiles/{package}/...
    
    CONFIGS_DIR="../settings"
    
    if [ ! -d "$CONFIGS_DIR" ] || [ -z "$(ls -A "$CONFIGS_DIR")" ]; then
        gum style --foreground 212 "Settings directory not found or is empty. (Expected at ../settings)"
        return
    fi

    # List directories in dotfiles to allow selection
    TARGETS=$(ls -d "$CONFIGS_DIR"/*/ | xargs -n 1 basename)
    SELECTED=$(echo "$TARGETS" | gum choose --no-limit --header "Select Configs to Stow")
    
    if [ -n "$SELECTED" ]; then
        for app in $SELECTED; do
            gum spin --spinner dot --title "Stowing $app..." -- stow -d "$CONFIGS_DIR" -t "$HOME" "$app"
        done
        gum style --foreground 76 "Configs applied."
    fi
}

setup_app_settings() {
    # Framework for App-Specific Settings (Post-install hooks)
    # Select which settings to apply
    OPTIONS=("Docker Setup" "Git Config" "System Services")
    SELECTED=$(printf "%s\n" "${OPTIONS[@]}" | gum choose --no-limit --header "Select App Settings")
    
    for opt in $SELECTED; do
        case "$opt" in
            "Docker Setup")
                if command -v docker &>/dev/null; then
                    gum spin --title "Configuring Docker..." -- sudo systemctl enable --now docker.service
                    gum spin --title "Adding user to docker group..." -- sudo usermod -aG docker $USER
                else
                    gum style --foreground 196 "Docker is not installed."
                fi
                ;;
            "Git Config")
                NAME=$(gum input --placeholder "Git User Name")
                EMAIL=$(gum input --placeholder "Git Email")
                if [ -n "$NAME" ] && [ -n "$EMAIL" ]; then
                    git config --global user.name "$NAME"
                    git config --global user.email "$EMAIL"
                fi
                ;;
            "System Services")
                # Add other services here
                gum spin --title "Enabling Bluetooth..." -- sudo systemctl enable --now bluetooth
                ;;
        esac
    done
}

# --- Main Logic ---

refresh_sudo
ensure_dependencies

# Ensure paru is installed
if ! command -v paru &> /dev/null; then
    gum spin --spinner dot --title "Installing Paru..." -- sudo pacman -S --noconfirm paru
fi

while true; do
    CHOICE=$(gum choose --header "CachyOS Automation Tool" \
        "Install Applications" \
        "System & Performance" \
        "Install Configs (Hyprland)" \
        "Apply App Settings" \
        "Exit")

    # Handle Cancel/Close
    if [ -z "$CHOICE" ] || [ "$CHOICE" == "Exit" ]; then
        break
    fi

    case "$CHOICE" in
        "Install Applications")
            if [ -f "$PACKAGES_FILE" ]; then
                MODE=$(gum choose --header "Installation Mode" "Select Manually" "Select by Category" "Install All")

                case "$MODE" in
                    "Select Manually")
                        # Filter out comments and empty lines
                        PKGS=$(grep -vE '^\s*#|^\s*$' "$PACKAGES_FILE")
                        SELECTED=$(echo "$PKGS" | gum choose --no-limit --header "Select Apps to Install")
                        [ -n "$SELECTED" ] && install_packages $SELECTED
                        ;;
                    "Select by Category")
                        # Extract categories
                        CATEGORIES=$(grep "^# --- " "$PACKAGES_FILE" | sed -E 's/^# --- (.*) ---$/\1/')
                        SELECTED_CATS=$(echo "$CATEGORIES" | gum choose --no-limit --header "Select Categories")
                        
                        if [ -n "$SELECTED_CATS" ]; then
                            TO_INSTALL=()
                            CURRENT_CAT=""
                            while IFS= read -r line; do
                                if [[ "$line" =~ ^#\ ---\ (.*)\ ---$ ]]; then
                                    CURRENT_CAT="${BASH_REMATCH[1]}"
                                elif [[ -n "$line" && ! "$line" =~ ^# ]]; then
                                    if echo "$SELECTED_CATS" | grep -Fxq "$CURRENT_CAT"; then
                                        TO_INSTALL+=("$line")
                                    fi
                                fi
                            done < "$PACKAGES_FILE"
                            [ ${#TO_INSTALL[@]} -gt 0 ] && install_packages "${TO_INSTALL[@]}"
                        fi
                        ;;
                    "Install All")
                        PKGS=$(grep -vE '^\s*#|^\s*$' "$PACKAGES_FILE")
                        [ -n "$PKGS" ] && install_packages $PKGS
                        ;;
                esac
            else
                gum style --foreground 196 "packages.txt not found."
            fi
            ;;
        "System & Performance")
            gum spin --spinner dot --title "Rating Mirrors..." -- sudo cachyos-rate-mirrors
            gum spin --spinner dot --title "Updating System..." -- paru -Syyu --noconfirm
            gum spin --spinner dot --title "Enabling Update Timer..." -- systemctl --user enable --now arch-update.timer
            # Install meta files
            gum spin --spinner dot --title "Installing Gaming Meta..." -- paru -S --noconfirm cachyos-gaming-meta
            gum style --foreground 76 "System optimized."
            ;;
        "Install Configs (Hyprland)")
            setup_configs
            ;;
        "Apply App Settings")
            setup_app_settings
            ;;
    esac
done
