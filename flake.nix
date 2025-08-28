{
  description = "NixOS Configuration - Modular and DRY";

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

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, vscode-server, plasma-manager, sops-nix }@inputs:
    let
      system = "x86_64-linux";
      
      # Import delle configurazioni centralizzate
      config = import ./config { inherit (nixpkgs) lib; };
      
      # Overlay per unstable packages
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
      
      # Funzione helper per creare sistemi
      mkHost = { hostname, profile, extraModules ? [], enableHomeManager ? true }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          
          specialArgs = { 
            inherit inputs config;
            hostConfig = config.hosts.${hostname};
          };
          
          modules = [
            # Overlay
            { nixpkgs.overlays = [ overlay-unstable ]; }
            
            # Core modules
            ./modules/core
            
            # Profile (laptop/desktop/server)
            ./profiles/${profile}.nix
            
            # Host specific configuration
            ./hosts/${profile}/${hostname}
            
            # Secrets management
            sops-nix.nixosModules.sops
            
            # User configuration
            ./users/filippo
            
            # Home Manager (se abilitato)
          ] ++ nixpkgs.lib.optionals enableHomeManager [
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.filippo = import ./users/filippo/home.nix;
                backupFileExtension = "backup";
                extraSpecialArgs = { 
                  inherit inputs config hostname;
                  hostConfig = config.hosts.${hostname};
                };
                sharedModules = [
                  plasma-manager.homeManagerModules.plasma-manager
                ];
              };
            }
          ] ++ extraModules;
        };
        
    in {
      # Host definitions
      nixosConfigurations = {
        # Laptops
        slimbook = mkHost {
          hostname = "slimbook";
          profile = "laptop";
          extraModules = [
            ./modules/services/wireguard.nix
            ./modules/development
          ];
        };
        
        # Desktops
        gaming = mkHost {
          hostname = "gaming";
          profile = "desktop";
          extraModules = [
            ./modules/gaming
          ];
        };
        
        # Servers
        dev-server = mkHost {
          hostname = "dev-server";
          profile = "server";
          enableHomeManager = false;
          extraModules = [
            ./modules/development
            vscode-server.nixosModules.default
            ./modules/services/vscode-server.nix
          ];
        };
      };
      
      # Development shell
      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          nixpkgs-fmt
          nix-tree
          nix-du
          sops
          age
          ssh-to-age
          jq
        ];
        
        shellHook = ''
          echo "🚀 NixOS Configuration Development Shell"
          echo "Available commands:"
          echo "  nixpkgs-fmt  - Format nix files"
          echo "  nix-tree     - Explore dependencies"
          echo "  sops         - Edit secrets"
          echo ""
          echo "Quick commands:"
          echo "  rebuild      - make rebuild"
          echo "  update       - make update"
          echo "  check        - make check"
          echo "  clean        - make clean"
        '';
      };
      
      # Formatter
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
