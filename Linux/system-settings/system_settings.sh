#!/bin/bash

configure_system_settings() {
    SYSTEM_SETTINGS_CHOICES=$(gum choose --no-limit --header "Select system settings to apply" "Rate Mirrors" "Enable Cachy Update" "Setup Firewall (UFW)")
}

install_system_settings() {
    if [[ -z "$SYSTEM_SETTINGS_CHOICES" ]]; then
        gum style --foreground 212 "No system settings selected."
        return 0
    fi

    gum style --foreground 212 "Acquiring sudo privilege..."
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

    if echo "$SYSTEM_SETTINGS_CHOICES" | grep -q "Rate Mirrors"; then
        gum spin --spinner dot --title "Rating Mirrors..." -- sudo cachyos-rate-mirrors
    fi

    if echo "$SYSTEM_SETTINGS_CHOICES" | grep -q "Enable Cachy Update"; then
        gum spin --show-output --spinner dot --title "Installing Cachy Update..." -- sudo pacman -S --noconfirm --needed cachy-update libnotify
        gum spin --show-output --spinner dot --title "Enabling Update Timer & Tray..." -- bash -c 'systemctl --user daemon-reload; systemctl --user enable --now arch-update.timer arch-update-tray.service'
        if systemctl --user is-active --quiet arch-update.timer; then
            gum style --foreground 76 "Cachy Update timer is active."
        else
            gum style --foreground 196 "Cachy Update timer is NOT active."
        fi
        sleep 1
    fi

    if echo "$SYSTEM_SETTINGS_CHOICES" | grep -q "Setup Firewall (UFW)"; then
        gum spin --spinner dot --title "Setting up UFW..." -- bash -c '
            sudo pacman -S --noconfirm --needed ufw
            sudo ufw limit 22/tcp
            sudo ufw allow 80/tcp
            sudo ufw allow 443/tcp
            sudo ufw default deny incoming
            sudo ufw default allow outgoing
            sudo ufw --force enable'
    fi

    gum style --foreground 76 "System settings applied."
}
