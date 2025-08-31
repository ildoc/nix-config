{ lib }:

rec {
  # ============================================================================
  # SYSTEM CONFIGURATION
  # ============================================================================
  system = {
    stateVersion = "25.05";
    architecture = "x86_64-linux";
    timezone = "Europe/Rome";
    locale = {
      default = "en_US.UTF-8";
      extra = "it_IT.UTF-8";
      # Formati italiani per date/numeri con messaggi in inglese
      settings = {
        LC_ADDRESS = "it_IT.UTF-8";
        LC_IDENTIFICATION = "it_IT.UTF-8";
        LC_MEASUREMENT = "it_IT.UTF-8";
        LC_MONETARY = "it_IT.UTF-8";
        LC_NAME = "it_IT.UTF-8";
        LC_NUMERIC = "it_IT.UTF-8";
        LC_PAPER = "it_IT.UTF-8";
        LC_TELEPHONE = "it_IT.UTF-8";
        LC_TIME = "it_IT.UTF-8";
        LC_MESSAGES = "en_US.UTF-8";
      };
    };
  };

  # ============================================================================
  # USER CONFIGURATION
  # ============================================================================
  users = {
    filippo = {
      username = "filippo";
      description = "Filippo";
      gitUserName = "ildoc";
      # gitEmail viene da sops
      groups = {
        base = [ "wheel" ];
        desktop = [ "networkmanager" "video" "audio" ];
        development = [ "docker" ];
        gaming = [ "gamemode" ];
      };
    };
  };

  # ============================================================================
  # NETWORK CONFIGURATION
  # ============================================================================
  network = {
    truenas = {
      ip = "192.168.0.123";
      homeNetwork = "192.168.0.0/24";
      shares = {
        foto = "/mnt/data/foto";
      };
    };
    
    location = {
      # Per Night Color e servizi location-based
      latitude = "44.4056";
      longitude = "8.9463";
      city = "Genoa";
      country = "Italy";
    };
  };

  # ============================================================================
  # PATHS AND DIRECTORIES
  # ============================================================================
  paths = {
    nixosConfig = "/etc/nixos";
    sopsKeyFile = "/var/lib/sops-nix/key.txt";
    userSopsKey = "~/.config/sops/age/keys.txt";
  };

  # ============================================================================
  # PORTS CONFIGURATION
  # ============================================================================
  ports = {
    ssh = 22;
    http = 80;
    https = 443;
    
    development = {
      common = 3000;
      alternate = 8080;
      additional = 9000;
    };
    
    gaming = {
      steam = [ 27015 27036 ];
      steamUDP = [ 27015 27031 27036 ];
    };
    
    kde = {
      # KDE Connect usa le porte 1714-1764 TCP e UDP
      connect = [ 1714 1715 1716 1717 1718 1719 1720 1721 1722 1723 1724 ];
    };
  };

  # ============================================================================
  # DESKTOP CONFIGURATION
  # ============================================================================
  desktop = {
    theme = {
      plasma = "org.kde.breezedark.desktop";
      gtk = "Breeze-Dark";
      icons = "breeze-dark";
      cursor = {
        theme = "breeze_cursors";
        size = 24;
      };
    };
    
    panel = {
      height = 44;
      location = "bottom";
    };
    
    virtualDesktops = {
      number = 4;
      names = [ "Main" "Dev" "Communication" "Extra" ];
    };
    
    powerManagement = {
      ac = {
        dimAfter = 600;      # 10 minuti
        screenOffAfter = 1800; # 30 minuti
      };
      battery = {
        dimAfter = 300;      # 5 minuti
        suspendAfter = 600;  # 10 minuti
      };
    };
  };

  # ============================================================================
  # DEVELOPMENT CONFIGURATION
  # ============================================================================
  development = {
    dotnet = {
      versions = [ "8.0" "9.0" ];
      telemetryOptOut = true;
    };
    
    nodejs = {
      version = "22";
    };
    
    docker = {
      pruneSchedule = "weekly";
      enableBuildkit = true;
    };
  };

  # ============================================================================
  # GAMING CONFIGURATION
  # ============================================================================
  gaming = {
    gamemode = {
      renice = 10;
      ioprio = 7;
    };
    
    audio = {
      sampleRate = 48000;
      quantum = 32;
    };
    
    kernel = {
      swappiness = 1;
      dirtyRatio = 3;
    };
  };

  # ============================================================================
  # HOST DEFINITIONS
  # ============================================================================
  hosts = {
    slimbook = {
      type = "laptop";
      description = "Slimbook Laptop - Development workstation";
      
      hardware = {
        cpu = "amd";
        graphics = "intel";
        hasBattery = true;
        hasBluetooth = true;
        hasWifi = true;
      };
      
      features = {
        desktop = true;
        development = true;
        wireguard = true;
        gaming = false;
        vscodeServer = false;
      };
      
      vpn = {
        connectionName = "Wg Casa";
        configFile = "wg0.conf";
        interface = "wg0";
        description = "Wireguard server di casa";
      };
      
      applications = {
        pinned = [
          "systemsettings"
          "org.kde.dolphin"
          "org.kde.konsole"
          "firefox"
          "org.telegram.desktop"
          "code"
          "teams-for-linux"
          "spotify"
        ];
        
        additional = [
          "insomnia"
          "obsidian"
          "libreoffice"
        ];
      };
    };
    
    gaming = {
      type = "desktop";
      description = "Gaming Desktop - High performance gaming rig";
      
      hardware = {
        cpu = "intel";
        graphics = "nvidia"; # o "amd" a seconda della tua GPU
        hasBattery = false;
        hasBluetooth = true;
        hasWifi = true;
      };
      
      features = {
        desktop = true;
        development = false;
        wireguard = false;
        gaming = true;
        vscodeServer = false;
      };
      
      applications = {
        pinned = [
          "org.kde.dolphin"
          "firefox"
          "org.kde.konsole"
          "steam"
          "discord"
          "lutris"
          "heroic"
          "spotify"
        ];
        
        additional = [
          "obs-studio"
        ];
      };
    };
    
    dev-server = {
      type = "server";
      description = "Development Server - Headless development environment";
      
      hardware = {
        cpu = "intel";
        graphics = "none";
        hasBattery = false;
        hasBluetooth = false;
        hasWifi = false;
      };
      
      features = {
        desktop = false;
        development = true;
        wireguard = false;
        gaming = false;
        vscodeServer = true;
      };
      
      applications = {
        pinned = [];
        additional = [];
      };
    };
  };

  # ============================================================================
  # PACKAGES CONFIGURATION
  # ============================================================================
  packages = {
    # Base system packages (tutti gli host)
    system = [
      "wget" "curl" "git" "htop" "tree" "lsof"
      "file" "which" "fastfetch" "unzip" "zip"
      "pciutils" "usbutils" "sops" "age"
    ];
    
    # Shell enhancements (tutti gli utenti)
    shell = [
      "fd" "ripgrep" "tldr" "jq" "yq-go" "httpie"
      "lazygit" "btop" "duf" "dust" "procs"
    ];
    
    # Desktop packages
    desktop = {
      core = [
        "firefox" "telegram-desktop" "vlc" "vscode"
      ];
      kde = [
        "kdePackages.dolphin"
        "kdePackages.spectacle"
        "kdePackages.okular"
        "kdePackages.gwenview"
        "kdePackages.konsole"
        "kdePackages.kcalc"
        "kdePackages.yakuake"
        "kdePackages.ark"
      ];
    };
    
    # Development packages
    development = {
      languages = [
        "nodejs" "python3" "go" "gcc" "gnumake" "cmake"
      ];
      tools = [
        "docker" "docker-compose" "kubectl"
        "postgresql" "sqlite" "postman"
      ];
    };
    
    # Gaming packages
    gaming = [
      "steam" "lutris" "heroic" "bottles"
      "gamemode" "mangohud" "goverlay"
      "discord" "obs-studio"
    ];
  };

  hostPackages = {
    slimbook = {
      system = [
        "teams-for-linux"
        "insomnia"
        "obsidian"
        "libreoffice"
      ];
      # Pacchetti speciali che richiedono unstable
      unstable = [
        "jetbrains-rider"  # Nome del pacchetto senza pkgs
      ];
    };
    
    gaming = {
      system = [
        "obs-studio"
      ];
      unstable = [];
    };
    
    dev-server = {
      system = [];
      unstable = [];
    };
  };
}
