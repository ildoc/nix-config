# Nix-config

## Setup iniziale:

al primo avvio modificare /etc/nixos/configurations.txt aggiungendo git ai packages e nix.settings.experimental-features = [ "nix-command" "flakes" ];

dopodichè sudo nixos-rebuild switch

poi piazzare in ~/.config/sops/age/keys.txt il file con la chiave age e successivamente

cd ~
git clone https://gitlab.local.ildoc.it/ildoc/nix-config.git
cd nix-config
rm hosts/[nomehost]/hardware-configuration.nix
sudo cp /etc/nixos/hardware-configuration.nix hosts/[nomehost]
sudo rm /etc/nixos/*
sudo ln -s flake.nix /etc/nixos/flake.nix
sudo nixos-rebuild switch .#[nomehost]





## Gestione dei secret

per modificare i secret fare sops secrets/secrets.yaml
