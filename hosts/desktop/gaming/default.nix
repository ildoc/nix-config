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
  
  hardware.nvidia = {
    # Override per gaming desktop
    powerManagement.enable = false;  # Desktop non ha bisogno di power management
    
    # Puoi anche specificare versioni driver specifiche se necessario
    # package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # ============================================================================
  # GAMING-SPECIFIC PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Aggiungi qui eventuali pacchetti specifici per questo host
    nvtopPackages.nvidia
  ];
}
