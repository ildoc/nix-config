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

  # ============================================================================
  # GAMING-SPECIFIC OVERRIDES
  # ============================================================================
  # Override del profilo se necessario
  
  # Num Lock abilitato all'avvio
  systemd.services.numlock-on = {
    description = "Enable NumLock on startup";
    wantedBy = [ "graphical.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.numlockx}/bin/numlockx on";
      StandardInput = "tty";
      TTYPath = "/dev/tty1";
    };
  };

  # ============================================================================
  # GAMING-SPECIFIC PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; 
    hostConfig.applications.additional ++ [
      # Aggiungi qui eventuali pacchetti specifici solo per questo desktop gaming
    ];
}
