#!/bin/bash

configure_applications() {
    local META_PKG_DIR="applications/meta-packages"

    # Step 1: Choose Mode
    local MODE=$(gum choose --header "Select Installation Mode" "Category Install" "Manual Install")

    if [ "$MODE" == "Category Install" ]; then
        # Hardcoded list of packages with descriptions for Gum
        # Format: "Directory | Description"
        local OPTIONS=(
            "core-apps   | Discord, Chrome, Brave, Parsec"
            "development | VS Code, Docker, Docker Compose, git"
            "gaming      | Steam, OBS, Modrinth, Meta-files"
        )

        # Join array with newlines for gum
        local CHOICES=$(printf "%s\n" "${OPTIONS[@]}")

        APPLICATIONS_SELECTED=$(echo "$CHOICES" | gum choose --no-limit --height 10 --header "Select Package Groups")
        MANUAL_PACKAGES_SELECTED=""
    elif [ "$MODE" == "Manual Install" ]; then
        # Combine all package lists
        local ALL_PKGS=$(cat "$META_PKG_DIR"/*.txt 2>/dev/null | grep -vE '^\s*#|^\s*$' | sort | uniq)
        
        if [ -n "$ALL_PKGS" ]; then
            MANUAL_PACKAGES_SELECTED=$(echo "$ALL_PKGS" | gum choose --no-limit --height 15 --header "Select Individual Packages")
        fi
        APPLICATIONS_SELECTED=""
    else
        APPLICATIONS_SELECTED=""
        MANUAL_PACKAGES_SELECTED=""
    fi
}

install_applications() {
    local META_PKG_DIR="applications/meta-packages"

    if [ -n "$APPLICATIONS_SELECTED" ]; then
        # Set Internal Field Separator to newline to handle multiple selections
        IFS=$'\n'
        for item in $APPLICATIONS_SELECTED; do
            # Extract directory name (text before " |")
            pkg=$(echo "$item" | cut -d '|' -f1 | xargs)
            
            local PKG_FILE="$META_PKG_DIR/$pkg.txt"
            if [ -f "$PKG_FILE" ]; then
                gum style --foreground 212 "Installing packages for $pkg..."
                # Read packages, ignoring comments and empty lines
                PACKAGES=$(grep -vE '^\s*#|^\s*$' "$PKG_FILE" | tr '\n' ' ')
                [ -n "$PACKAGES" ] && paru -S --noconfirm $PACKAGES
            fi
        done
        unset IFS
    fi

    if [ -n "$MANUAL_PACKAGES_SELECTED" ]; then
        gum style --foreground 212 "Installing manually selected packages..."
        local MANUAL_LIST=$(echo "$MANUAL_PACKAGES_SELECTED" | tr '\n' ' ')
        paru -S --noconfirm $MANUAL_LIST
    fi

    if [ -n "$APPLICATIONS_SELECTED" ] || [ -n "$MANUAL_PACKAGES_SELECTED" ]; then
        gum style --foreground 76 "Finished installing applications."
    else
        gum style --foreground 212 "No package groups selected."
    fi
}
