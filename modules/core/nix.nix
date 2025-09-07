{ config, lib, globalConfig, ... }:

let
  cfg = globalConfig;
in
{
  # ============================================================================
  # NIX CONFIGURATION - STABILE
  # ============================================================================
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0;
      
      keep-outputs = true;
      keep-derivations = true;

      # Cache
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      extra-substituters = [ "file:///var/cache/nix" ];
      
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      
      # Gestione spazio disco
      max-free = toString (5 * 1024 * 1024 * 1024);  # 5GB
      min-free = toString (1 * 1024 * 1024 * 1024);  # 1GB
      
      # Connessioni di rete
      http-connections = 25;
      max-substitution-jobs = 8;
    };
    
    # ============================================================================
    # FIX: GC e Optimise con restart sicuro
    # ============================================================================
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
      persistent = true;
    };
    
    optimise = {
      automatic = true;
      dates = [ "03:45" ]; # Una sola data, non una lista
    };
    
    # ============================================================================
    # CONFIGURAZIONE STABILE
    # ============================================================================
    extraOptions = ''
      # Timeout connection
      connect-timeout = 5
      # Fallback se binary cache fallisce
      fallback = true
      # Non mantenere outputs/derivations durante switch per evitare problemi
      keep-outputs = false
      keep-derivations = false
    '';
  };
  
  # ============================================================================
  # FIX: Timer systemd per GC e Optimize
  # ============================================================================
  systemd.services = {
    nix-gc = {
      restartIfChanged = false;
      unitConfig = {
        # Non riavviare se già in esecuzione
        RefuseManualStart = false;
        RefuseManualStop = false;
      };
    };
    
    nix-optimise = {
      restartIfChanged = false;
      unitConfig = {
        RefuseManualStart = false;
        RefuseManualStop = false;
      };
    };
  };
  
  systemd.timers = {
    nix-gc = {
      timerConfig = {
        Persistent = true;
        OnCalendar = "weekly";
      };
    };
    
    nix-optimise = {
      timerConfig = {
        Persistent = true;
        OnCalendar = "03:45";
      };
    };
  };
}
