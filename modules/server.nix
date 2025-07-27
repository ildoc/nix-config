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
  
  # Soluzione per VS Code Server: nix-ld
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
    ];
  };
  
  # Pacchetti server (kubectl già incluso in common.nix)
  environment.systemPackages = with pkgs; [
    # Monitoring
    htop
    iotop
    netdata
    
    # Network tools
    bind # per dig, nslookup
    traceroute
    
    # Text editors
    nano
    
    # Node.js per compatibilità VS Code Server
    nodejs_20
    
    # Server utilities
    rsync
    screen
    tmux
  ];
  
  # Firewall per server
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      22    # SSH
      80    # HTTP
      443   # HTTPS
    ];
  };
  
  # Ottimizzazioni server
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
    HandleSuspendKey=ignore
    HandleHibernateKey=ignore
  '';
  
  # Disable unnecessary services for server
  sound.enable = false;
  hardware.pulseaudio.enable = false;
}
