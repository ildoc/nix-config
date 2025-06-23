{ config, pkgs, ... }:

{
  # Configurazione specifica per server
  
  # Disabilita GUI
  services.xserver.enable = false;
  
  # Pacchetti server
  environment.systemPackages = with pkgs; [
    # Container orchestration
    docker
    docker-compose
    kubectl
    
    # Monitoring
    htop
    iotop
    netdata
    
    # Network tools
    bind # per dig, nslookup
    
    # Text editors
    nano
    vim
  ];

  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
  
  # Kubernetes tools
  services.kubernetes = {
    roles = []; # Configurare secondo necessità
  };
  
  # Utente nel gruppo docker
  users.users.filippo.extraGroups = [ "docker" ];
  
  # VSCode Server per sviluppo remoto
  services.vscode-server.enable = true;
  
  # Firewall più restrittivo per server
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      22    # SSH
      8000  # VSCode Server (porta di default)
    ];
    # Aggiungi altre porte secondo necessità
  };
}
