{ config, pkgs, lib, inputs, hostConfig, globalConfig, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "slimbook";

  hardware.enableRedistributableFirmware = true;

  # Pacchetti specifici per questo host
  environment.systemPackages = with pkgs; [
    unstable.jetbrains.rider  # IDE per .NET
    prismlauncher            # Minecraft launcher
    # teams-for-linux        # Commentato se non necessario
  ];
}
