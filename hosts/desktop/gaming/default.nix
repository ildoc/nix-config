{ config, pkgs, lib, inputs, hostConfig, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ============================================================================
  # HOST-SPECIFIC SETTINGS
  # ============================================================================
  networking.hostName = "gaming";

  hardware.enableRedistributableFirmware = true;
  
  # ============================================================================
  # GAMING-SPECIFIC PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Aggiungi qui eventuali pacchetti specifici per questo host
    nvtopPackages.nvidia
  ];
}
