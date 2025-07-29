{ config, pkgs, ... }:

{
  # Configurazione gaming aggiornata per NixOS 25.05
  
  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Hardware accelerazione (sintassi aggiornata per 25.05)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    
    # Drivers aggiuntivi
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # GameMode
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
    };
  };

  # Pacchetti gaming
  environment.systemPackages = with pkgs; [
    # Gaming platforms
    steam
    lutris
    heroic
    
    # Gaming utilities
    gamemode
    mangohud
    
    # Communication
    discord
    
    # Streaming/Recording
    obs-studio
  ];

  # Firewall per gaming
  networking.firewall = {
    allowedTCPPorts = [ 
      27015  # Steam
      27036  # Steam
    ];
    allowedUDPPorts = [
      27015  # Steam
      27031  # Steam
      27036  # Steam
    ];
  };
  
  # Audio ottimizzato per gaming
  services.pipewire.extraConfig.pipewire."92-low-latency" = {
    context.properties = {
      default.clock.rate = 48000;
      default.clock.quantum = 32;
      default.clock.min-quantum = 32;
      default.clock.max-quantum = 32;
    };
  };
  
  # Ottimizzazioni performance
  boot.kernel.sysctl = {
    "vm.swappiness" = 1;
    "vm.dirty_ratio" = 3;
    "vm.dirty_background_ratio" = 2;
    
    # Network per gaming
    "net.core.rmem_default" = 31457280;
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_default" = 31457280;
    "net.core.wmem_max" = 134217728;
    "net.core.netdev_max_backlog" = 5000;
  };
  
  # Kernel parameters
  boot.kernelParams = [
    "preempt=full"
    "nowatchdog"
    "nmi_watchdog=0"
  ];
  
  # Gruppo gaming per l'utente
  users.users.filippo.extraGroups = [ "gamemode" ];
  
  # Gaming services
  services = {
    irqbalance.enable = true;
    ratbagd.enable = true;
  };
}
