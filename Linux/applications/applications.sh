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
        local ALL_PKGS=$(cat "$META_PKG_DIR"/*.txt 2>/dev/null | sed 's/\r//g' | grep -vE '^\s*#|^\s*$' | awk '{$1=$1};1' | sort | uniq)
        
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

    # Refresh sudo credentials to prevent paru from hanging on password prompt
    sudo -v

    local PACKAGES_TO_INSTALL=""

    if [ -n "$APPLICATIONS_SELECTED" ]; then
        # Set Internal Field Separator to newline to handle multiple selections
        IFS=$'\n'
        for item in $APPLICATIONS_SELECTED; do
            # Extract directory name (text before " |")
            pkg=$(echo "$item" | cut -d '|' -f1 | xargs)
            local PKG_FILE="$META_PKG_DIR/$pkg.txt"
            if [ -f "$PKG_FILE" ]; then
                # Append packages from file to the list, adding a space at the end
                PACKAGES_TO_INSTALL+=$(cat "$PKG_FILE" | sed 's/\r//g' | grep -vE '^\s*#|^\s*$' | awk '{$1=$1};1' | tr '\n' ' ')" "
            fi
        done
    fi
    unset IFS

    if [ -n "$MANUAL_PACKAGES_SELECTED" ]; then
        PACKAGES_TO_INSTALL+=$(echo "$MANUAL_PACKAGES_SELECTED" | tr '\n' ' ')
    fi

    # Trim leading/trailing whitespace from the final list
    PACKAGES_TO_INSTALL=$(echo "$PACKAGES_TO_INSTALL" | awk '{$1=$1};1')

    if [ -n "$PACKAGES_TO_INSTALL" ]; then
        gum style --foreground 212 "Installing all selected packages..."
        # Use `yes` to auto-confirm any prompts that --noconfirm might miss
        if ! yes | paru -S --noconfirm --skipreview --needed $PACKAGES_TO_INSTALL; then
            gum style --foreground 212 "Batch install failed. Attempting to install packages individually..."
            for package in $PACKAGES_TO_INSTALL; do
                yes | paru -S --noconfirm --skipreview --needed "$package" || gum style --foreground 196 "--> Failed to install '$package', skipping."
            done
        fi
        gum style --foreground 76 "Finished installing applications."
    else
        gum style --foreground 212 "No package groups selected."
    fi
}
