# Nix-config

## Setup iniziale:

al primo avvio modificare /etc/nixos/configurations.txt aggiungendo git ai packages e nix.settings.experimental-features = [ "nix-command" "flakes" ];

dopodichè sudo nixos-rebuild switch

poi

git clone 



piazzare in ~/.config/sops/age/keys.txt il file con la chiave age


## Gestione dei secret

per modificare i secret fare sops secrets/secrets.yaml
