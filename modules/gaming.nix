{ config, pkgs, ... }:

{
  # ============================================================================
  # CONFIGURAZIONE GAMING WORKSTATION
  # ============================================================================
  # Ottimizzazioni specifiche per gaming e performance
  # Compatibile con NixOS 25.05

  # === PIATTAFORME GAMING ===
  programs.steam = {
    enable = true;
    
    # === STEAM REMOTE FEATURES ===
    remotePlay.openFirewall = true;      # Steam Remote Play
    dedicatedServer.openFirewall = true; # Server dedicati Steam
    
    # === COMPATIBILITÀ PROTON ===
    # Proton viene gestito automaticamente da Steam
    # Le impostazioni sono configurabili da Steam client
  };

  # === ACCELERAZIONE HARDWARE ===
  # Configurazione aggiornata per NixOS 25.05
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Supporto giochi 32-bit legacy
    
    # === DRIVER AGGIUNTIVI ===
    extraPackages = with pkgs; [
      # Intel graphics support
      intel-media-driver    # VAAPI moderna per Intel
      intel-vaapi-driver    # VAAPI legacy per Intel più vecchie
      
      # Video acceleration
      vaapiVdpau           # VAAPI to VDPAU wrapper
      libvdpau-va-gl       # VDPAU driver basato su VA-GL
    ];
  };

  # === GAMEMODE ===
  # Ottimizzazioni runtime per gaming
  programs.gamemode = {
    enable = true;
    
    settings = {
      # === CONFIGURAZIONI GENERALI ===
      general = {
        renice = 10;                    # Priorità processo più alta
        ioprio = 7;                     # Priorità I/O più alta
        inhibit_screensaver = 1;        # Disabilita screensaver
        softrealtime = "auto";          # Real-time scheduling automatico
        reaper_freq = 5;                # Frequenza pulizia processi zombie
      };
      
      # === FILTRO APPLICAZIONI ===
      filter = {
        # Solo queste applicazioni attivano GameMode
        whitelist = [
          "steam"
          "lutris"
          "heroic"
          "minecraft-launcher"
          "bottles"
        ];
      };
      
      # === OTTIMIZZAZIONI GPU ===
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";  # Per GPU AMD
      };
      
      # === OTTIMIZZAZIONI CPU ===
      cpu = {
        park_cores = "no";               # Non mettere core in sleep
        pin_cores = "no";                # Non vincolare core specifici
      };
    };
  };

  # === APPLICAZIONI GAMING ===
  environment.systemPackages = with pkgs; [
    # === PIATTAFORME ===
    steam                   # Piattaforma principale
    lutris                  # Wine gaming frontend
    heroic                  # Epic Games & GOG launcher
    bottles                 # Wine prefix manager
    
    # === UTILITIES GAMING ===
    gamemode               # Runtime optimizations
    mangohud              # Performance overlay
    goverlay              # MangoHud configurator GUI
    
    # === WINE E COMPATIBILITÀ ===
    wineWowPackages.stable # Wine per Windows games
    winetricks            # Wine configuration helper
    
    # === COMUNICAZIONE ===
    discord               # Voice chat gaming
    
    # === STREAMING E RECORDING ===
    obs-studio            # Streaming/recording software
    
    # === EMULAZIONE ===
    # retroarch           # Multi-system emulator (opzionale)
  ];

  # === OTTIMIZZAZIONI AUDIO GAMING ===
  # Configurazione PipeWire per bassa latenza
  services.pipewire.extraConfig.pipewire."92-low-latency" = {
    context.properties = {
      default.clock.rate = 48000;        # Sample rate ottimale
      default.clock.quantum = 32;        # Buffer size basso
      default.clock.min-quantum = 32;    # Buffer minimo
      default.clock.max-quantum = 32;    # Buffer massimo
    };
  };

  # === OTTIMIZZAZIONI KERNEL ===
  # Parametri del kernel per performance gaming
  boot.kernel.sysctl = {
    # === GESTIONE MEMORIA ===
    "vm.swappiness" = 1;                  # Evita swap aggressivo
    "vm.dirty_ratio" = 3;                 # Flush memoria cache presto
    "vm.dirty_background_ratio" = 2;      # Background flushing
    
    # === OTTIMIZZAZIONI NETWORK PER GAMING ===
    # Buffer di ricezione
    "net.core.rmem_default" = 31457280;   # 30MB default
    "net.core.rmem_max" = 134217728;      # 128MB massimo
    
    # Buffer di trasmissione  
    "net.core.wmem_default" = 31457280;   # 30MB default
    "net.core.wmem_max" = 134217728;      # 128MB massimo
    
    # Queue network
    "net.core.netdev_max_backlog" = 5000; # Più pacchetti in coda
  };
  
  # === PARAMETRI BOOT ===
  # Ottimizzazioni a livello kernel
  boot.kernelParams = [
    "preempt=full"          # Preemption completa per responsività
    "nowatchdog"            # Disabilita watchdog per ridurre overhead
    "nmi_watchdog=0"        # Disabilita NMI watchdog
  ];

  # === FIREWALL GAMING ===
  # Porte per gaming e Steam
  networking.firewall = {
    allowedTCPPorts = [ 
      27015                 # Steam
      27036                 # Steam
      # 7777                # Porte giochi specifici (esempio)
    ];
    
    allowedUDPPorts = [
      27015                 # Steam
      27031                 # Steam  
      27036                 # Steam
      # 7777                # Porte giochi specifici (esempio)
    ];
  };
  
  # === GRUPPI UTENTE ===
  # Permessi necessari per gaming
  users.users.filippo.extraGroups = [ 
    "gamemode"              # Accesso a GameMode
    "audio"                 # Controllo audio diretto
  ];
  
  # === SERVIZI GAMING ===
  services = {
    # Bilanciamento IRQ per ridurre latenza
    irqbalance.enable = true;
    
    # Supporto mouse gaming avanzato
    ratbagd.enable = true;
  };

  # === OTTIMIZZAZIONI FILESYSTEM ===
  # Mount options per performance (se hai filesystem dedicato per giochi)
  # fileSystems."/home/filippo/Games" = {
  #   device = "/dev/disk/by-label/games";
  #   fsType = "ext4";
  #   options = [ "noatime" "defaults" ]; # noatime per performance
  # };
}
