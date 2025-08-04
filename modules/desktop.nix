{ config, pkgs, ... }:

{
  imports = [
    ./desktop/display.nix
    ./desktop/audio.nix
    ./desktop/networking.nix
    ./desktop/fonts.nix
    ./desktop/applications.nix
    # ./desktop/power-management.nix
    ./desktop/network-storage.nix 
  ];

  services.printing.enable = true;

  programs.kdeconnect.enable = true;

  networking.firewall = {
    allowedTCPPorts = [ 1714 1715 1716 1717 1718 1719 1720 1721 1722 1723 1724 ];
    allowedUDPPorts = [ 1714 1715 1716 1717 1718 1719 1720 1721 1722 1723 1724 ];
  };
}
