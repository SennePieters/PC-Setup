# rank the mirrors & update system
sudo cachyos-rate-mirrors
paru -Syyu

# enable update checker
systemctl --user enable --now arch-update.timer

# gaming meta files
paru -S cachyos-gaming-meta

# install my apps
paru -S discord
paru -S steam
paru -S google-chrome
paru -S visual-studio-code-bin
paru -S obs-studio
paru -S parsec-bin