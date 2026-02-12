source ./helper.sh

refresh_sudo

clear

# Ensure paru is installed
if ! command -v paru &> /dev/null; then
    gum spin --spinner dot --title "Installing Paru..." -- sudo pacman -S --noconfirm paru
fi

# Ensure system is up-to-date before installing anything
if gum confirm "Update system?"; then
    gum style --foreground 212 "Updating System..."
    paru -Syyu --noconfirm
fi

# Source modules to load their functions
source ./system-settings/system_settings.sh
source ./applications/applications.sh
source ./application-settings/application_settings.sh
source ./de-customizations/de_customizations.sh

MODULES=(
    "System Settings"
    "Applications"
    "Application Settings"
    "DE Customizations"
)

while true; do
    clear
    CHOICE=$(gum choose --no-limit --header "Select with Space, Run with Enter" "${MODULES[@]}" "Exit")
    if [ -z "$CHOICE" ]; then
        continue
    fi

    if [ "$CHOICE" == "Exit" ]; then
        break
    fi

    # Pass 1: Configure (Ask all questions)
    IFS=$'\n'
    for item in $CHOICE; do
        if [ "$item" == "Exit" ]; then
            continue
        fi
        
        case "$item" in
            "System Settings")          configure_system_settings || true ;;
            "Applications")             configure_applications || true ;;
            "Application Settings")     configure_application_settings || true ;;
            "DE Customizations")        configure_de_customizations || true ;;
        esac
    done
    unset IFS

    # Pass 2: Install (Apply everything)
    IFS=$'\n'
    for item in $CHOICE; do
        if [ "$item" == "Exit" ]; then continue; fi
        
        case "$item" in
            "System Settings")          install_system_settings || true ;;
            "Applications")             install_applications || true ;;
            "Application Settings")     install_application_settings || true ;;
            "DE Customizations")        install_de_customizations || true ;;
        esac
    done
    unset IFS

    gum style --foreground 76 "All selected tasks completed."
    sleep 1
done
