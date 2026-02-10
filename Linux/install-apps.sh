# rank the mirrors & update system
sudo cachyos-rate-mirrors
paru -Syyu

# enable update checker
systemctl --user enable --now arch-update.timer

# gaming meta files
paru -S cachyos-gaming-meta

# install my apps and verify if installed succesfully, otherwise return error.
paru -S discord
paru -S steam
paru -S google-chrome
paru -S brave-bin
paru -S visual-studio-code-bin
paru -S obs-studio
paru -S parsec-bin
paru -S modrinth-app-bin

# docker
paru -S docker docker-compose
sudo systemctl enable --now docker.service
sudo usermod -aG docker $USER
# test
docker run hello-world
# if it says hello-world it is completed