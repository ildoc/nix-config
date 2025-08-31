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
  # Gestiti correttamente come pacchetti veri, non stringhe
  environment.systemPackages = with pkgs; [
    # Applicazioni desktop aggiuntive per slimbook
    teams-for-linux
    insomnia
    obsidian
    libreoffice
    
    # Unstable packages
    unstable.jetbrains.rider
  ];
}
