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

      keep-outputs = true;
      keep-derivations = true;
      
      # Parallel downloads
      http-connections = 50;
      max-substitution-jobs = 16;
    };
    
    # Garbage collection automatica
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
      persistent = true;
      randomizedDelaySec = "45min";
    };
    
    # Ottimizzazione store
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };
}
