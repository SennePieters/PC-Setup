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
source ./install-apps/install_apps.sh
source ./system-settings/system_settings.sh
source ./install-configs/install_configs.sh
source ./app-settings/app_settings.sh

MODULES=(
    "System Settings"
    "Install Applications"
    "App Settings"
    "Install Configs (Hyprland)"
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
            "Install Applications")     configure_install_apps || true ;;
            "System Settings")          configure_system_settings || true ;;
            "Install Configs (Hyprland)") configure_install_configs || true ;;
            "App Settings")             configure_app_settings || true ;;
        esac
    done
    unset IFS

    # Pass 2: Install (Apply everything)
    IFS=$'\n'
    for item in $CHOICE; do
        if [ "$item" == "Exit" ]; then continue; fi
        
        case "$item" in
            "Install Applications")     install_install_apps || true ;;
            "System Settings")          install_system_settings || true ;;
            "Install Configs (Hyprland)") install_install_configs || true ;;
            "App Settings")             install_app_settings || true ;;
        esac
    done
    unset IFS

    gum style --foreground 76 "All selected tasks completed."
    sleep 1
done
