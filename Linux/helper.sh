#!/bin/bash

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
