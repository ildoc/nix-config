{ config, pkgs, lib, ... }:

{
  imports = [
    ./config.nix
    ./config/vpn.nix
    ./locale.nix
    ./nix-config.nix
    ./shell.nix
    ./system-packages.nix
    ./users.nix
  ];

  # SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
      PermitRootLogin = "no";
      MaxAuthTries = 3;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
    };
  };

  # Basic firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # System version - DO NOT MODIFY
  system.stateVersion = "25.05";
}
