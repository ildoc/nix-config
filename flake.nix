{
  description = "Configurazione NixOS multi-host di Filippo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, vscode-server, plasma-manager, sops-nix }:
    let
      system = "x86_64-linux";
      
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      mkSystemBase = hostname: modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          
          modules = [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [ overlay-unstable ];
            })
            
            ./hosts/${hostname}/configuration.nix
            ./modules/common.nix
            ./modules/users/filippo.nix
            sops-nix.nixosModules.sops
            ./modules/secrets.nix
            
            { networking.hostName = hostname; }
            
          ] ++ modules;
        };

      mkSystemWithHM = hostname: modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          
          modules = [
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [ overlay-unstable ];
            })
            
            ./hosts/${hostname}/configuration.nix
            ./modules/common.nix
            ./modules/users/filippo.nix
            sops-nix.nixosModules.sops
            ./modules/secrets.nix

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.filippo = import ./users/filippo.nix;
                backupFileExtension = "backup";
                extraSpecialArgs = { 
                  inherit hostname;
                };                
                sharedModules = [
                  plasma-manager.homeManagerModules.plasma-manager
                ];
              };
              
              networking.hostName = hostname;
            }
            
          ] ++ modules;
        };
    in {
      nixosConfigurations = {
        dev-server = mkSystemBase "dev-server" [
          ./modules/server.nix
          ./modules/development.nix
          vscode-server.nixosModules.default
        ];

        slimbook = mkSystemWithHM "slimbook" [
          ./modules/desktop.nix
          ./modules/development.nix
          ./modules/wireguard.nix
        ];

        gaming = mkSystemWithHM "gaming" [
          ./modules/desktop.nix
          ./modules/gaming.nix
        ];
      };
      
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      
      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          nixpkgs-fmt
          nix-tree
          nix-du
          sops
          age
          ssh-to-age
        ];
        
        shellHook = ''
          echo "🚀 NixOS Configuration Development Shell"
          echo "Available commands:"
          echo "  nixpkgs-fmt *.nix  - Format nix files"
          echo "  nix-tree           - Explore dependencies"
          echo "  nix-du             - Analyze disk usage"
          echo "  sops               - Edit secrets"
          echo "  age-keygen         - Generate age keys"
          echo "  ssh-to-age         - Convert SSH to age key"
        '';
      };
    };
}
