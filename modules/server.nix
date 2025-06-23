{ config, pkgs, ... }:

{
  # Configurazione specifica per server
  
  # Disabilita GUI
  services.xserver.enable = false;
  
  # Pacchetti server
  environment.systemPackages = with pkgs; [
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
  
  # Kubernetes tools
  services.kubernetes = {
    roles = []; # Configurare secondo necessità
  };
  
  
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
