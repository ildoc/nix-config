{ config, pkgs, lib, inputs, hostConfig, globalConfig, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "slimbook";

  # Hardware specifics
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  
  hardware.enableRedistributableFirmware = true;

  # Pacchetti specifici per questo host
  # I pacchetti base sono gestiti dai moduli core e desktop
  environment.systemPackages = with pkgs; [
    # Applicazioni specifiche per slimbook non coperte dai moduli base
    # teams-for-linux      # Comunicazione aziendale
    
    # Unstable packages specifici per development
    unstable.jetbrains.rider  # IDE per .NET
    prismlauncher
  ];
}
