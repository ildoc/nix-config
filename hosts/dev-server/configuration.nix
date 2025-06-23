{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Configurazioni specifiche per server
  networking.hostName = "dev-server";
  
  # Disabilita servizi desktop non necessari
  services.xserver.enable = false;
  sound.enable = false;
  hardware.pulseaudio.enable = false;
  
  # Ottimizzazioni per server
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
    HandleSuspendKey=ignore
    HandleHibernateKey=ignore
  '';
  
  # Firewall più restrittivo
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ]; # SSH, HTTP, HTTPS
  };
}
