{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Configurazioni specifiche per desktop gaming
  networking.hostName = "gaming";
  
  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Hardware accelerazione ottimizzata per gaming
  hardware.graphics = {  # Rinominato da hardware.opengl
    enable = true;
    enable32Bit = true;  # Rinominato da driSupport32Bit
    
    # Drivers aggiuntivi per compatibilità
    extraPackages = with pkgs; [
      intel-media-driver # VAAPI su Intel
      intel-vaapi-driver  # Rinominato da vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  
  # Audio ottimizzato per gaming con bassa latenza
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    
    # Configurazione a bassa latenza
    extraConfig.pipewire."92-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 32;
        default.clock.min-quantum = 32;
        default.clock.max-quantum = 32;
      };
    };
  };
  
  # Ottimizzazioni performance per gaming
  boot.kernel.sysctl = {
    # Memoria
    "vm.swappiness" = 1;  # Riduce al minimo lo swap
    "vm.dirty_ratio" = 3;
    "vm.dirty_background_ratio" = 2;
    
    # Network per gaming
    "net.core.rmem_default" = 31457280;
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_default" = 31457280;
    "net.core.wmem_max" = 134217728;
    "net.core.netdev_max_backlog" = 5000;
  };
  
  # Kernel parameters per gaming
  boot.kernelParams = [
    # Preemption model per gaming
    "preempt=full"
    
    # Disable watchdog per ridurre overhead
    "nowatchdog"
    "nmi_watchdog=0"
  ];
  
  # GameMode ottimizzato
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        ioprio = 7;
        inhibit_screensaver = 1;
        softrealtime = "auto";
        reaper_freq = 5;
      };
      
      filter = {
        whitelist = [
          "steam"
          "lutris"
          "heroic"
          "minecraft-launcher"
        ];
      };
      
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
      
      cpu = {
        park_cores = "no";
        pin_cores = "no";
      };
    };
  };
  
  # Steam ottimizzato
  programs.steam = {
    enable = true;  
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  
  # Firewall per gaming
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 
      22     # SSH  
      27015  # Steam
      27036  # Steam
    ];
    allowedUDPPorts = [
      27015  # Steam
      27031  # Steam
      27036  # Steam
    ];
  };
  
  # Servizi per gaming
  services = {
    # Reduce scheduling latency
    irqbalance.enable = true;
    
    # Gaming mouse support
    ratbagd.enable = true;
  };
  
  # Gruppo gaming per l'utente
  users.users.filippo.extraGroups = [ "gamemode" ];
  
  # Num Lock abilitato all'avvio
  # Per Plasma 6, NumLock è gestito attraverso le impostazioni di sistema
  # Possiamo usare un servizio systemd come alternativa
  systemd.services.numlock-on = {
    description = "Enable NumLock on startup";
    wantedBy = [ "graphical.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.numlockx}/bin/numlockx on";
      StandardInput = "tty";
      TTYPath = "/dev/tty1";
    };
  };
}
