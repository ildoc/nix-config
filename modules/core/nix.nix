{ config, lib, globalConfig, ... }:

let
  cfg = globalConfig;
in
{
  # ============================================================================
  # NIX CONFIGURATION - CENTRALIZZATA
  # ============================================================================
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0;
      
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      
      # Gestione spazio disco
      max-free = toString (5 * 1024 * 1024 * 1024);  # 5GB
      min-free = toString (1 * 1024 * 1024 * 1024);  # 1GB
      
      # RIMOSSI: keep-outputs e keep-derivations che causano problemi
      # RIDOTTI: valori più conservativi per evitare sovraccarico
      http-connections = 25;  # Ridotto da 50
      max-substitution-jobs = 8;  # Ridotto da 16
    };
    
    # Garbage collection automatica
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
      persistent = true;
      # RIMOSSO: randomizedDelaySec che può causare conflitti
    };
    
    # Ottimizzazione store
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
    
    # Extra options SICURE
    extraOptions = ''
      # Mantieni derivazioni per rollback
      keep-outputs = false
      keep-derivations = false
      # Timeout connection più ragionevoli
      connect-timeout = 5
      # Fallback se binary cache fallisce
      fallback = true
    '';
  };
}
