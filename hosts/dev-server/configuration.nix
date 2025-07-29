{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Configurazioni specifiche per server
  networking.hostName = "dev-server";
  
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";  # Installa GRUB sul disco principale
  };

  # Disabilita servizi desktop non necessari
  services.xserver.enable = false;
  sound.enable = false;
  services.pulseaudio.enable = false;
  
  # Ottimizzazioni per server
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
    HandleSuspendKey=ignore
    HandleHibernateKey=ignore
  '';
  
  # Firewall per server con porte development
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      22    # SSH
      80    # HTTP
      443   # HTTPS
      3000  # Dev server comune
      8080  # Dev server alternativo
    ];
  };
  
  # Monitoraggio del server (opzionale)
  # services.netdata = {
  #   enable = true;
  #   config = {
  #     global = {
  #       "default port" = "19999";
  #       "bind to" = "localhost";
  #     };
  #   };
  # };
}
