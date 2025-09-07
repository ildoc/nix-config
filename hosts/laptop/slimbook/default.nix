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
      mesa
      amdvlk
    ];
  };
  
  hardware.enableRedistributableFirmware = true;

  # Pacchetti specifici per questo host
  environment.systemPackages = with pkgs; [
    # Solo pacchetti SPECIFICI per slimbook non coperti dai moduli
    unstable.jetbrains.rider  # IDE per .NET
    prismlauncher            # Minecraft launcher
    # teams-for-linux        # Commentato se non necessario
  ];
}
