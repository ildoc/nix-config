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
  # BASE PACKAGES - Ora gestiti dal modulo core/packages.nix
  # ============================================================================
  # I pacchetti base sono definiti in modules/core/packages.nix
}
