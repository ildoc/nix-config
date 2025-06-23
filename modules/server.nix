{ config, pkgs, ... }:

{
  # Configurazione specifica per server
  
  # Disabilita GUI
  services.xserver.enable = false;
  
  # Variabili d'ambiente specifiche per server
  environment.variables = {
    KUBE_EDITOR = "nano";
    EDITOR = "nano";
    VISUAL = "nano";
  };
  
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
    
    # Node.js per compatibilità VS Code Server
    nodejs_20
  ];
  
  # Kubernetes tools
  services.kubernetes = {
    roles = []; # Configurare secondo necessità
  };
  
  # VS Code Server - configurazione dichiarativa
  services.vscode-server = {
    enable = true;
    enableFHS = true; # Abilita FHS per compatibilità estensioni
  };
  
  # Abilita il servizio automaticamente per l'utente filippo
  systemd.user.services.auto-fix-vscode-server = {
    wantedBy = [ "default.target" ];
  };
  
  # Firewall per server
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      22    # SSH
    ];
  };
}
