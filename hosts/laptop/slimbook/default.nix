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
  environment.systemPackages = with pkgs; let
    hostPkgs = globalConfig.hostPackages.${config.networking.hostName} or { system = []; unstable = []; };
    systemPkgs = map (name: pkgs.${name}) hostPkgs.system;
    unstablePkgs = map (name: pkgs.unstable.${name}) hostPkgs.unstable;
  in systemPkgs ++ unstablePkgs;
}
