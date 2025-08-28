{ config, lib, inputs, hostConfig, ... }:

let
  cfg = inputs.config;
in
{
  networking = {
    # Hostname viene impostato dal profile/host
    
    # Firewall di base
    firewall = {
      enable = true;
      allowedTCPPorts = [ cfg.ports.ssh ];
    };
    
    # DNS
    nameservers = lib.mkDefault [ "1.1.1.1" "1.0.0.1" ];
  };
  
  # SSH sempre abilitato
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
}
