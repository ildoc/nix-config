{
  description = "Configurazione NixOS multi-host di Filippo";

  inputs = {
    # === CORE INPUTS ===
    # Canale stabile di nixpkgs - base del sistema
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Canale unstable per pacchetti più recenti
    # Utilizzato tramite overlay per mantenere stabilità del sistema base
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # === USER ENVIRONMENT ===
    # Home Manager per la gestione delle configurazioni utente
    # Permette di gestire dotfiles e configurazioni personali in modo dichiarativo
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs"; # Evita duplicazioni di nixpkgs
    };

    # === DEVELOPMENT TOOLS ===
    # Supporto per VS Code Server remoto
    # Necessario per sviluppo remoto su server headless
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, vscode-server }:
    let
      # === SYSTEM CONFIGURATION ===
      system = "x86_64-linux";
      
      # Overlay per integrare pacchetti unstable in modo sicuro
      # Permette di accedere a pkgs.unstable.packagename
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      # === SYSTEM BUILDERS ===
      
      # Builder per sistemi base (principalmente server)
      # Non include Home Manager per ridurre overhead su server headless
      mkSystemBase = hostname: modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          
          # Moduli sempre presenti in ogni sistema
          modules = [
            # Applica overlay per accesso a pacchetti unstable
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [ overlay-unstable ];
            })
            
            # Configurazione hardware specifica dell'host
            ./hosts/${hostname}/configuration.nix
            
            # Configurazioni comuni a tutti i sistemi
            ./modules/common.nix
            
            # Imposta hostname dinamicamente
            { networking.hostName = hostname; }
            
          ] ++ modules; # Moduli aggiuntivi passati come parametro
        };

      # Builder per sistemi desktop con Home Manager
      # Include gestione completa dell'ambiente utente
      mkSystemWithHM = hostname: modules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          
          modules = [
            # Overlay per pacchetti unstable
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [ overlay-unstable ];
            })
            
            # Configurazioni di base
            ./hosts/${hostname}/configuration.nix
            ./modules/common.nix

            # === HOME MANAGER INTEGRATION ===
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                # Usa lo stesso pkgs del sistema per coerenza
                useGlobalPkgs = true;
                # Installa pacchetti nel profilo utente invece che nel sistema
                useUserPackages = true;
                # Configurazione utente specifica
                users.filippo = import ./users/filippo.nix;
                
                # === GESTIONE BACKUP AUTOMATICO ===
                # Backup automatico dei file esistenti
                backupFileExtension = "backup";
                
                # Passa inputs aggiuntivi a Home Manager se necessario
                # extraSpecialArgs = { inherit inputs; };
              };
              
              # Hostname configuration
              networking.hostName = hostname;
            }
            
          ] ++ modules;
        };
    in {
      # === HOST DEFINITIONS ===
      
      nixosConfigurations = {
        # Server di sviluppo headless
        # Ottimizzato per performance e stabilità
        dev-server = mkSystemBase "dev-server" [
          ./modules/server.nix      # Configurazioni server-specific
          ./modules/development.nix # Tools di sviluppo
          vscode-server.nixosModules.default # Supporto VS Code remoto
        ];

        # Laptop principale - focus su produttività e battery life
        slimbook = mkSystemWithHM "slimbook" [
          ./modules/desktop.nix     # Ambiente desktop KDE
          ./modules/development.nix # Tools di sviluppo completi
        ];

        # Workstation gaming - performance oriented
        gaming = mkSystemWithHM "gaming" [
          ./modules/desktop.nix     # Ambiente desktop base
          ./modules/gaming.nix      # Ottimizzazioni e software gaming
        ];
      };
      
      # === ADDITIONAL OUTPUTS ===
      
      # Formatters per sviluppo del flake stesso
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
      
      # DevShell per sviluppo e manutenzione della configurazione
      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          nixpkgs-fmt    # Formatter per file .nix
          nix-tree       # Visualizzazione dipendenze
          nix-du         # Analisi spazio disco
        ];
        
        shellHook = ''
          echo "🚀 NixOS Configuration Development Shell"
          echo "Available commands:"
          echo "  nixpkgs-fmt *.nix  - Format nix files"
          echo "  nix-tree           - Explore dependencies"
          echo "  nix-du             - Analyze disk usage"
        '';
      };
    };
}
