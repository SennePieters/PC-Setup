#!/bin/bash
# Framework for App-Specific Settings (Post-install hooks)
# Select which settings to apply

configure_application_settings() {
    APPLICATION_SETTINGS_OPTIONS=("Docker Setup" "Git Config" "System Services")
    APPLICATION_SETTINGS_SELECTED=$(printf "%s\n" "${APPLICATION_SETTINGS_OPTIONS[@]}" | gum choose --no-limit --header "Select App Settings")

    if echo "$APPLICATION_SETTINGS_SELECTED" | grep -q "Git Config"; then
        while true; do
            gum style --foreground 212 "Configuring Git Details..."
            APP_GIT_NAME=$(gum input --placeholder "Git User Name")
            APP_GIT_EMAIL=$(gum input --placeholder "Git Email")

            if [ -z "$APP_GIT_NAME" ] || [ -z "$APP_GIT_EMAIL" ]; then
                gum style --foreground 196 "Name and Email cannot be empty."
                continue
            fi

            echo "Name:  $APP_GIT_NAME"
            echo "Email: $APP_GIT_EMAIL"

            if gum confirm "Is this correct?"; then
                break
            fi
        done
    fi
}

install_application_settings() {
    for opt in $APPLICATION_SETTINGS_SELECTED; do
        case "$opt" in
            "Docker Setup")
                gum style --foreground 212 "Configuring Docker..."
                sudo systemctl enable --now docker.socket
                sudo usermod -aG docker $USER
                gum style --foreground 212 "Testing Docker..."
                OUTPUT=$(sg docker -c "docker run hello-world" 2>&1)
                echo "$OUTPUT"
                if [[ "$OUTPUT" == *"Hello from Docker!"* ]]; then
                    gum style --foreground 76 "Docker setup verified successfully!"
                else
                    gum style --foreground 196 "Docker test failed."
                fi
                ;;
            "Git Config")
                gum style --foreground 212 "Configuring Git..."
                if git config --global user.name "$APP_GIT_NAME" && \
                   git config --global user.email "$APP_GIT_EMAIL"; then
                    gum style --foreground 76 "Git configured."
                else
                    gum style --foreground 196 "Failed to configure Git. Is git installed?"
                fi
                ;;
            "System Services")
                gum style --foreground 212 "No additional system services configured."
                ;;
        esac
    done
}