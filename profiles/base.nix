{ config, pkgs, lib, globalConfig, hostConfig, ... }:

let
  cfg = globalConfig;
in
{
  imports = [
    ../modules/core
  ];

  # ============================================================================
  # SYSTEM CONFIGURATION
  # ============================================================================
  system.stateVersion = cfg.system.stateVersion;
  
  # ============================================================================
  # BASE PACKAGES - Definiti direttamente qui, non più in config/default.nix
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Base system tools
    wget
    curl
    git
    htop
    tree
    lsof
    file
    which
    fastfetch
    unzip
    zip
    
    # Version control
    git
    
    # Container tools
    kubectl
    
    # Hardware info
    pciutils
    usbutils
    
    # Security
    sops
    age
  ];
}
