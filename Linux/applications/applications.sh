#!/bin/bash

configure_applications() {
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
}

install_applications() {
    local META_PKG_DIR="applications/meta-packages"

    if [ -n "$APPLICATIONS_SELECTED" ]; then
        # Set Internal Field Separator to newline to handle multiple selections
        IFS=$'\n'
        for item in $APPLICATIONS_SELECTED; do
            # Extract directory name (text before " |")
            pkg=$(echo "$item" | cut -d '|' -f1 | xargs)
            
            (
                cd "$META_PKG_DIR/$pkg"
                # Handle PKGBUILD.sh if present (rename to PKGBUILD for makepkg)
                if [ -f "PKGBUILD.sh" ] && [ ! -f "PKGBUILD" ]; then
                    mv "PKGBUILD.sh" "PKGBUILD"
                fi
                makepkg -si --noconfirm
            )
        done
        unset IFS
        gum style --foreground 76 "Finished installing package groups."
    else
        gum style --foreground 212 "No package groups selected."
    fi
}