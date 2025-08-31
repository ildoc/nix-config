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
  # BASE PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; 
    cfg.packages.system ++
    [
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

  # ============================================================================
  # USERS CONFIGURATION
  # ============================================================================
  # Root shell already configured in modules/core/shell.nix
  # users.users.root.shell = pkgs.zsh; <- REMOVED (duplicate)
}
