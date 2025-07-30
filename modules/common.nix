{ config, pkgs, lib, ... }:

{
  # ============================================================================
  # CONFIGURAZIONI COMUNI A TUTTI GLI HOST
  # ============================================================================
  # Questo modulo contiene tutte le configurazioni di base condivise
  # tra server, desktop e gaming workstation

  # === LOCALIZZAZIONE ===
  time.timeZone = "Europe/Rome";
  
  i18n = {
    defaultLocale = "it_IT.UTF-8";
    
    # Configurazioni regionali specifiche per l'Italia
    extraLocaleSettings = {
      LC_ADDRESS = "it_IT.UTF-8";
      LC_IDENTIFICATION = "it_IT.UTF-8";
      LC_MEASUREMENT = "it_IT.UTF-8";
      LC_MONETARY = "it_IT.UTF-8";
      LC_NAME = "it_IT.UTF-8";
      LC_NUMERIC = "it_IT.UTF-8";
      LC_PAPER = "it_IT.UTF-8";
      LC_TELEPHONE = "it_IT.UTF-8";
      LC_TIME = "it_IT.UTF-8";
    };
  };

  # === CONFIGURAZIONE TASTIERA ===
  console = {
    useXkbConfig = true; # Usa la stessa configurazione di X11
  };
  
  # Num Lock abilitato all'avvio solo sui sistemi desktop
  services.xserver.xkb.options = lib.mkIf (config.services.xserver.enable) "numlock:on";

  # === CONFIGURAZIONE NIX ===
  nix = {
    settings = {
      # === FEATURES SPERIMENTALI ===
      experimental-features = [ "nix-command" "flakes" ];
      
      # === OTTIMIZZAZIONI PERFORMANCE ===
      auto-optimise-store = true;
      max-jobs = "auto";           # Usa tutti i core disponibili
      cores = 0;                   # Usa tutti i core per singolo job
      
      # === BINARY CACHES ===
      # Cache ufficiali per velocizzare download
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      
      # === GESTIONE SPAZIO DISCO ===
      # Previene il riempimento completo del disco
      max-free = toString (5 * 1024 * 1024 * 1024);  # 5GB liberi
      min-free = toString (1 * 1024 * 1024 * 1024);  # 1GB minimo
    };
    
    # === GARBAGE COLLECTION ===
    # Pulizia automatica e intelligente del store
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
      persistent = true; # Riprova se il sistema era spento
    };
    
    # === OTTIMIZZAZIONE STORE ===
    # Rimozione file duplicati per risparmiare spazio
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  # Permetti software proprietario (necessario per alcuni driver e applicazioni)
  nixpkgs.config.allowUnfree = true;

  # === CONFIGURAZIONE SHELL ===
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    
    # === OH MY ZSH ===
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      
      plugins = [ 
        "git"                     # Alias e funzioni Git
        "sudo"                    # Doppio ESC per aggiungere sudo
        "docker"                  # Autocompletamento Docker
        "docker-compose"          # Autocompletamento Docker Compose
        "kubectl"                 # Autocompletamento Kubernetes
        "history-substring-search" # Ricerca nella cronologia
        "colored-man-pages"       # Man pages colorate
        "command-not-found"       # Suggerimenti per comandi non trovati
      ];
    };
    
    # === CONFIGURAZIONE SHELL INTERATTIVA ===
    interactiveShellInit = ''
      # === CONFIGURAZIONE HISTORY ===
      HISTSIZE=10000
      SAVEHIST=10000
      setopt SHARE_HISTORY           # Condividi history tra sessioni
      setopt HIST_VERIFY             # Verifica prima di eseguire da history
      setopt EXTENDED_HISTORY        # Timestamp nella history
      setopt HIST_IGNORE_DUPS        # Ignora duplicati consecutivi
      setopt HIST_IGNORE_ALL_DUPS    # Rimuovi tutti i duplicati
      setopt HIST_REDUCE_BLANKS      # Rimuovi spazi extra
      
      # === ALIAS COMUNI ===
      alias ll="ls -la"
      alias la="ls -A"
      alias l="ls -CF"
      alias ".."="cd .."
      alias "..."="cd ../.."
      alias grep="grep --color=auto"
      alias df="df -h"
      alias du="du -h"
      
      # === NIXOS MANAGEMENT ALIASES ===
      # Utilizzano hostname dinamico per flessibilità
      HOSTNAME=$(hostname)
      
      alias rebuild="sudo nixos-rebuild switch --flake /etc/nixos#$HOSTNAME"
      alias rebuild-test="sudo nixos-rebuild test --flake /etc/nixos#$HOSTNAME"
      alias rebuild-boot="sudo nixos-rebuild boot --flake /etc/nixos#$HOSTNAME"
      alias rebuild-dry="sudo nixos-rebuild dry-run --flake /etc/nixos#$HOSTNAME"
      alias flake-update="sudo nix flake update /etc/nixos"
      alias gc-full="sudo nix-collect-garbage -d && nix-store --gc"
      
      # === KUBERNETES SHORTCUTS ===
      if command -v kubectl >/dev/null 2>&1; then
        alias k="kubectl"
      fi
      
      # === FUNZIONI UTILITY ===
      
      # Crea directory e cd
      mkcd() { mkdir -p "$1" && cd "$1"; }
      
      # Backup con timestamp
      backup() { cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"; }
      
      # Ricerca processi
      psg() { ps aux | grep -v grep | grep "$1"; }
      
      # Estrazione universale archivi
      extract() {
        if [ -f "$1" ]; then
          case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.rar) unrar x "$1" ;;
            *.gz) gunzip "$1" ;;
            *.tar) tar xf "$1" ;;
            *.tbz2) tar xjf "$1" ;;
            *.tgz) tar xzf "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "'$1' cannot be extracted via extract()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }
      
      # === CONFIGURAZIONI HOST-SPECIFIC ===
      case "$HOSTNAME" in
        "dev-server")
          export DOCKER_HOST="unix:///var/run/docker.sock"
          export KUBE_EDITOR="nano"
          export EDITOR="nano"
          export VISUAL="nano"
          ;;
        "slimbook")
          export KUBE_EDITOR="nano"
          export EDITOR="nano"
          export VISUAL="nano"
          # Alias per applicazioni GUI (solo per utenti non root)
          if [[ "$USER" != "root" ]]; then
            alias rider="nohup rider > /dev/null 2>&1 &"
          fi
          ;;
        "gaming")
          export EDITOR="nano"
          export VISUAL="nano"
          # Gaming aliases
          if [[ "$USER" != "root" ]]; then
            alias steam="nohup steam > /dev/null 2>&1 &"
          fi
          ;;
      esac
      
      # === CONFIGURAZIONE PATH ===
      # Aggiungi ~/.local/bin per utenti normali
      if [[ "$USER" != "root" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        DEFAULT_USER="filippo" # Nasconde username nel prompt
      fi
    '';
  };

  # === EDITOR DI DEFAULT ===
  programs.nano.enable = true;
  environment.variables = {
    EDITOR = "nano";
    VISUAL = "nano";
  };

  # === CONFIGURAZIONE SSH ===
  services.openssh = {
    enable = true;
    
    settings = {
      # === AUTENTICAZIONE ===
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
      PermitRootLogin = "no";
      
      # === SICUREZZA ===
      MaxAuthTries = 3;
      ClientAliveInterval = 300;    # Keep alive ogni 5 minuti
      ClientAliveCountMax = 2;      # Disconnetti dopo 10 minuti inattivo
    };
  };

  # === FIREWALL BASE ===
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]; # SSH sempre disponibile
  };

  # === PACCHETTI SISTEMA BASE ===
  environment.systemPackages = with pkgs; [
    # === NETWORK TOOLS ===
    wget
    curl
    nmap
    tcpdump
    
    # === SYSTEM UTILITIES ===
    htop
    tree
    lsof
    strace
    file
    which
    fastfetch
    
    # === ARCHIVING ===
    unzip
    zip
    
    # === VERSION CONTROL ===
    git
    
    # === HARDWARE INSPECTION ===
    pciutils   # lspci
    usbutils   # lsusb
    
    # === KUBERNETES TOOLS ===
    # Disponibili su tutti gli host per coerenza
    kubectl
    
  ] ++ lib.optionals config.services.xserver.enable [
    # === DESKTOP-ONLY PACKAGES ===
    numlockx   # Gestione Num Lock per X11
  ];

  # === CONFIGURAZIONE UTENTI ===
  
  # Utente principale
  users.users.filippo = {
    isNormalUser = true;
    description = "Filippo";
    extraGroups = [ 
      "wheel"           # Sudo access
      "networkmanager"  # Network management
    ];
    shell = pkgs.zsh;
  };

  # Root con ZSH per coerenza
  users.users.root = {
    shell = pkgs.zsh;
  };

  # === SUDO CONFIGURATION ===
  # Wheel group non richiede password (comodo per development)
  security.sudo.wheelNeedsPassword = false;

  # === SYSTEM VERSION ===
  # IMPORTANTE: Non modificare mai questo valore!
  # Determina la compatibilità delle migrazioni di stato
  system.stateVersion = "24.05";
}
