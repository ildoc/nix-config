{ config, lib, globalConfig, ... }:

let
  cfg = globalConfig;
in
{
  # ============================================================================
  # NIX CONFIGURATION - OTTIMIZZATA
  # ============================================================================
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      
      # Ottimizzazioni CPU
      max-jobs = "auto";
      cores = 0; # Usa tutti i core disponibili
      
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
      
      # Ottimizzazioni di rete più conservative
      http-connections = 25;
      max-substitution-jobs = 8;
      
      # Abilita build in sandbox per sicurezza
      sandbox = true;
      
      # Trusted users per operazioni senza sudo
      trusted-users = [ "@wheel" ];
    };
    
    # Garbage collection automatica ottimizzata
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d"; # Mantieni 2 settimane invece di 7 giorni
      persistent = true;
    };
    
    # Ottimizzazione store
    optimise = {
      automatic = true;
      dates = [ "03:45" ]; # Esegui di notte
    };
    
    # Extra options sicure e ottimizzate
    extraOptions = ''
      # Mantieni outputs per debug
      keep-outputs = true
      keep-derivations = true
      
      # Timeout più ragionevoli
      connect-timeout = 5
      stalled-download-timeout = 300
      
      # Fallback se binary cache fallisce
      fallback = true
      
      # Warn invece di fail per firme non fidate
      warn-dirty = true
      
      # Abilita diff-hook per vedere differenze
      diff-hook = ${lib.getExe config.nix.package} store diff-closures
    '';
  };
}
