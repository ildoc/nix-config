{
  description = "Configurazione NixOS multi-host di Filippo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # VSCode Server per sviluppo remoto
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, vscode-server }:
    let
      system = "x86_64-linux";
      
      # Overlay per accedere ai pacchetti unstable
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
      
      # Funzione helper per creare configurazioni
      mkSystem = hostname: modules: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
          ./hosts/${hostname}/configuration.nix
          ./modules/common.nix
          ./users/filippo.nix
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
    in
    {
      nixosConfigurations = {
        # Cambia questi nomi come preferisci
        dev-server = mkSystem "dev-server" [
          ./modules/server.nix
          ./modules/development.nix
          vscode-server.nixosModules.default
        ];

        # Laptop per lavoro
        work-laptop = mkSystem "work-laptop" [
          ./modules/desktop.nix
          ./modules/development.nix
        ];

        # Desktop per gaming
        gaming-rig = mkSystem "gaming-rig" [
          ./modules/desktop.nix
          ./modules/gaming.nix
        ];
      };
    };
}
