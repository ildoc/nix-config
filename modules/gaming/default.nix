{
  config,
  pkgs,
  lib,
  inputs,
  globalConfig,
  hostConfig,
  ...
}:

let
  cfg = globalConfig;
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
    # Memory management - Gaming vuole swappiness più basso
    "vm.swappiness" = lib.mkForce gamingCfg.kernel.swappiness; # mkForce per override
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
  # GAMING PACKAGES - Definiti qui invece che in config/default.nix
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Gaming platforms
    steam
    lutris
    heroic
    bottles

    # Gaming tools
    gamemode
    mangohud
    goverlay

    # Communication
    discord

    # Streaming/Recording
    obs-studio
  ];

  # ============================================================================
  # USER GROUPS
  # ============================================================================
  users.users.filippo.extraGroups = [
    "gamemode"
    "audio"
  ];

  # ============================================================================
  # SERVICES
  # ============================================================================
  services = {
    irqbalance.enable = true;
    ratbagd.enable = true;
  };
}
