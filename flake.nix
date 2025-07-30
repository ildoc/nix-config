{
  description = "Configurazione NixOS multi-host di Filippo";

  inputs = {
    # Canale stabile di nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Canale unstable, utile per pacchetti più recenti (via overlay)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager per la gestione della configurazione utente
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs"; # Usa lo stesso nixpkgs
    };

    # Supporto per codice remoto (vscode-server)
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, vscode-server }:
    let
      system = "x86_64-linux";

      # Overlay che aggiunge `unstable` a ogni pkgs
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      # Base system senza Home Manager (es. server headless)
      mkSystemBase = hostname: modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            # Applica overlay unstable
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [ overlay-unstable ];
            })
            # Configurazione hardware e moduli host-specifici
            ./hosts/${hostname}/configuration.nix
            ./modules/common.nix
            { networking.hostName = hostname; }
          ] ++ modules;
        };

      # Sistema con supporto Home Manager
      mkSystemWithHM = hostname: modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [ overlay-unstable ];
            })
            ./hosts/${hostname}/configuration.nix
            ./modules/common.nix

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.filippo = import ./users/filippo.nix;
              };
              networking.hostName = hostname;
            }
          ] ++ modules;
        };
    in {
      # Definizione dei sistemi
      nixosConfigurations = {
        dev-server = mkSystemBase "dev-server" [
          ./modules/server.nix
          ./modules/development.nix
          vscode-server.nixosModules.default
        ];

        slimbook = mkSystemWithHM "slimbook" [
          ./modules/desktop.nix
          ./modules/development.nix
        ];

        gaming = mkSystemWithHM "gaming" [
          ./modules/desktop.nix
          ./modules/gaming.nix
        ];
      };
    };
}
