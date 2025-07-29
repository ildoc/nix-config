{
  description = "Configurazione NixOS multi-host di Filippo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, vscode-server }:
    let
      system = "x86_64-linux";
      
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
      
      # Sistema base senza Home Manager (per server)
      mkSystemBase = hostname: modules: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
          ./hosts/${hostname}/configuration.nix
          ./modules/common.nix
          { networking.hostName = hostname; }
        ] ++ modules;
      };
      
      # Sistema con Home Manager (per desktop/slimbook)
      mkSystemWithHM = hostname: modules: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
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
    in
    {
      nixosConfigurations = {
        # Server: solo NixOS, configurazione minimal
        dev-server = mkSystemBase "dev-server" [
          ./modules/server.nix
          ./modules/development.nix
          vscode-server.nixosModules.default
        ];

        # slimbook: NixOS + Home Manager per GUI - SEMPLIFICATO
        slimbook = mkSystemWithHM "slimbook" [
          ./modules/desktop.nix
          ./modules/development.nix
        ];

        # Desktop: NixOS + Home Manager per gaming
        gaming = mkSystemWithHM "gaming" [
          ./modules/desktop.nix
          ./modules/gaming.nix
        ];
      };
    };
}
