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
  
  # Soluzione più semplice e affidabile per VS Code Server: nix-ld
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Librerie necessarie per VS Code Server e le sue estensioni
      stdenv.cc.cc
      zlib
      fuse3
      icu
      nss
      openssl
      curl
      expat
      # Aggiungi altre librerie se necessario
    ];
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
  
  # Firewall per server
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      22    # SSH
    ];
  };
}
