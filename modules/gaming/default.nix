{ config, pkgs, lib, inputs, hostConfig, ... }:

let
  cfg = inputs.config;
  gamingCfg = cfg.gaming;
in
{
  # ============================================================================
  # GAMING PLATFORMS
  # ============================================================================
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # ============================================================================
  # HARDWARE ACCELERATION
  # ============================================================================
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # ============================================================================
  # GAMEMODE
  # ============================================================================
  programs.gamemode = {
    enable = true;
    
    settings = {
      general = {
        renice = gamingCfg.gamemode.renice;
        ioprio = gamingCfg.gamemode.ioprio;
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
          "bottles"
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

  # ============================================================================
  # AUDIO OPTIMIZATION
  # ============================================================================
  services.pipewire.extraConfig.pipewire."92-low-latency" = {
    context.properties = {
      default.clock.rate = gamingCfg.audio.sampleRate;
      default.clock.quantum = gamingCfg.audio.quantum;
      default.clock.min-quantum = gamingCfg.audio.quantum;
      default.clock.max-quantum = gamingCfg.audio.quantum;
    };
  };

  # ============================================================================
  # KERNEL OPTIMIZATIONS
  # ============================================================================
  boot.kernel.sysctl = {
    # Memory management
    "vm.swappiness" = gamingCfg.kernel.swappiness;
    "vm.dirty_ratio" = gamingCfg.kernel.dirtyRatio;
    "vm.dirty_background_ratio" = 2;
    
    # Network for gaming
    "net.core.rmem_default" = 31457280;
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_default" = 31457280;
    "net.core.wmem_max" = 134217728;
    "net.core.netdev_max_backlog" = 5000;
  };
  
  boot.kernelParams = [
    "preempt=full"
    "nowatchdog"
    "nmi_watchdog=0"
  ];

  # ============================================================================
  # FIREWALL
  # ============================================================================
  networking.firewall = {
    allowedTCPPorts = cfg.ports.gaming.steam;
    allowedUDPPorts = cfg.ports.gaming.steamUDP;
  };

  # ============================================================================
  # GAMING PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; cfg.packages.gaming;
  
  # ============================================================================
  # USER GROUPS
  # ============================================================================
  users.users.filippo.extraGroups = [ "gamemode" "audio" ];
  
  # ============================================================================
  # SERVICES
  # ============================================================================
  services = {
    irqbalance.enable = true;
    ratbagd.enable = true;
  };
}
