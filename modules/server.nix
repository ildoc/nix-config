{ config, pkgs, ... }:

{
  # ============================================================================
  # CONFIGURAZIONE SERVER HEADLESS
  # ============================================================================
  # Ottimizzazioni per server di sviluppo senza interfaccia grafica
  # Focus su stabilità, sicurezza e performance

  # === DISABILITA SERVIZI GUI ===
  # Nessun display server necessario
  services.xserver.enable = false;
  
  # === CONFIGURAZIONE EDITOR ===
  # Editor da terminale per ambiente server
  environment.variables = {
    KUBE_EDITOR = "nano";
    EDITOR = "nano";
    VISUAL = "nano";
  };
  
  # === COMPATIBILITÀ VS CODE SERVER ===
  # Soluzione per VS Code Server e estensioni
  programs.nix-ld = {
    enable = true;
    
    # Librerie necessarie per VS Code Server
    libraries = with pkgs; [
      stdenv.cc.cc          # Compilatore C/C++
      zlib                  # Libreria compressione
      fuse3                 # Filesystem userspace
      icu                   # Unicode support
      nss                   # Network Security Services
      openssl               # Crittografia
      curl                  # HTTP client
      expat                 # XML parser
    ];
  };
  
  # === PACCHETTI SERVER ===
  environment.systemPackages = with pkgs; [
    # === MONITORING E PERFORMANCE ===
    htop                    # Monitor processi interattivo
    iotop                   # Monitor I/O
    netdata                 # Monitoring real-time web-based
    
    # === NETWORK DIAGNOSTICS ===
    bind                    # Tools DNS (dig, nslookup)
    traceroute              # Tracciamento route network
    iperf3                  # Test bandwidth network
    
    # === EDITOR TERMINALE ===
    nano                    # Editor semplice e veloce
    vim                     # Editor avanzato
    
    # === DEVELOPMENT RUNTIME ===
    nodejs_20               # Node.js per VS Code Server
    
    # === SERVER UTILITIES ===
    rsync                   # Sincronizzazione file
    screen                  # Terminal multiplexer
    tmux                    # Terminal multiplexer moderno
    
    # === BACKUP E SYNC ===
    rclone                  # Cloud storage sync
    borgbackup              # Backup incrementali
    
    # === CONTAINER MANAGEMENT ===
    docker-compose          # Multi-container orchestration
    
    # === LOG ANALYSIS ===
    lnav                    # Log navigator
    
    # === SYSTEM INFO ===
    neofetch                # System info display
  ];
  
  # === CONFIGURAZIONE FIREWALL ===
  networking.firewall = {
    enable = true;
    
    # === PORTE BASE SERVER ===
    allowedTCPPorts = [ 
      22                    # SSH
      80                    # HTTP
      443                   # HTTPS
      
      # === DEVELOPMENT PORTS ===
      3000                  # Development server comune
      8080                  # Development server alternativo
      9000                  # Development server
      
      # === MONITORING ===
      # 19999               # Netdata (solo localhost di default)
    ];
    
    # Porte UDP se necessarie
    allowedUDPPorts = [
      # Aggiungi qui porte UDP specifiche se necessario
    ];
  };
  
  # === OTTIMIZZAZIONI POWER MANAGEMENT ===
  # Disabilita gestione power per server
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
    HandleSuspendKey=ignore
    HandleHibernateKey=ignore
    HandleLidSwitch=ignore
  '';
  
  # === DISABILITA SERVIZI NON NECESSARI ===
  # Audio non necessario su server
  sound.enable = false;
  services.pulseaudio.enable = false;
  
  # === CONFIGURAZIONI RETE SERVER ===
  # Ottimizzazioni network per server
  boot.kernel.sysctl = {
    # === TCP TUNING ===
    "net.core.rmem_max" = 134217728;      # 128MB buffer ricezione
    "net.core.wmem_max" = 134217728;      # 128MB buffer trasmissione
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";
    
    # === CONNECTION HANDLING ===
    "net.core.somaxconn" = 1024;          # Queue connessioni
    "net.ipv4.tcp_max_syn_backlog" = 1024;
    
    # === PERFORMANCE ===
    "net.ipv4.tcp_congestion_control" = "bbr"; # Algoritmo controllo congestione
    "vm.swappiness" = 10;                 # Riduci uso swap
  };
  
  # === SERVIZI OPZIONALI ===
  # Questi servizi possono essere abilitati se necessario
  
  # === MONITORING AVANZATO ===
  # services.netdata = {
  #   enable = true;
  #   config = {
  #     global = {
  #       "default port" = "19999";
  #       "bind to" = "localhost"; # Solo accesso locale per sicurezza
  #     };
  #   };
  # };
  
  # === BACKUP AUTOMATICO ===
  # services.borgbackup.jobs.daily = {
  #   paths = [
  #     "/home"
  #     "/etc"
  #     "/var/lib"
  #   ];
  #   exclude = [
  #     "/home/*/.cache"
  #     "/home/*/.tmp"
  #   ];
  #   repo = "/backup/borg";
  #   encryption = {
  #     mode = "repokey-blake2";
  #     passCommand = "cat /etc/borg-passphrase";
  #   };
  #   compression = "auto,lzma";
  #   startAt = "daily";
  # };
  
  # === CONFIGURAZIONE DOCKER ===
  # Ottimizzazioni Docker per server
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    
    # === CONFIGURAZIONI PRODUZIONE ===
    logDriver = "json-file";
    extraOptions = ''
      --log-opt max-size=10m
      --log-opt max-file=3
    '';
  };
  
  # === LOG ROTATION ===
  # Gestione log per evitare riempimento disco
  services.logrotate = {
    enable = true;
    settings = {
      "/var/log/messages" = {
        frequency = "daily";
        rotate = 7;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
      };
    };
  };
}
