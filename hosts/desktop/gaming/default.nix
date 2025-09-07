{ config, pkgs, lib, inputs, hostConfig, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ============================================================================
  # HOST-SPECIFIC SETTINGS
  # ============================================================================
  networking.hostName = "gaming";

  # ============================================================================
  # HARDWARE SPECIFICS
  # ============================================================================
  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  
  # Graphics configuration (adjust based on your actual GPU)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  
  hardware.enableRedistributableFirmware = true;

  # RIMOSSO: systemd.services.numlock-on - gestito da KDE/Plasma

  # ============================================================================
  # GAMING-SPECIFIC PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Aggiungi qui eventuali pacchetti specifici per questo host
  ];
}
