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
in
{
  imports = [
    ./base.nix
  ];

  # ============================================================================
  # SERVER-SPECIFIC BOOT CONFIGURATION
  # ============================================================================
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda"; # Aggiusta in base al tuo sistema
      };
    };

    # Server: compressione veloce per boot rapidi
    initrd = {
      compressor = "gzip";
    };

    # Kernel parameters per server
    kernelParams = [
      "console=tty0"
      "console=ttyS0,115200"
    ];
  };

  # ============================================================================
  # DISABLE GUI
  # ============================================================================
  services.xserver.enable = false;
  sound.enable = false;
  services.pulseaudio.enable = false;

  # ============================================================================
  # SERVER NETWORK
  # ============================================================================
  networking = {
    useDHCP = lib.mkDefault true;
  };

  # ============================================================================
  # SERVER OPTIMIZATIONS
  # ============================================================================
  boot.kernel.sysctl = {
    # TCP tuning
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";

    # Connection handling
    "net.core.somaxconn" = 1024;
    "net.ipv4.tcp_max_syn_backlog" = 1024;

    # Performance
    "net.ipv4.tcp_congestion_control" = "bbr";
    "vm.swappiness" = lib.mkDefault globalConfig.sysctl.server.swappiness;
  };

  # ============================================================================
  # POWER MANAGEMENT
  # ============================================================================
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
    HandleSuspendKey=ignore
    HandleHibernateKey=ignore
    HandleLidSwitch=ignore
  '';

  # ============================================================================
  # MONITORING
  # ============================================================================
  services.netdata = lib.mkIf (hostConfig.features.monitoring or false) {
    enable = true;
    config = {
      global = {
        "default port" = "19999";
        "bind to" = "localhost";
      };
    };
  };

  # ============================================================================
  # LOG ROTATION
  # ============================================================================
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

  # ============================================================================
  # SERVER PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Monitoring
    htop
    iotop
    netdata

    # Network diagnostics
    bind
    traceroute
    iperf3

    # Editor
    nano
    vim

    # Utilities
    rsync
    screen
    tmux

    # Backup
    rclone
    borgbackup

    # Log analysis
    lnav

    # System info
    neofetch
  ];

  # ============================================================================
  # FIREWALL
  # ============================================================================
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      cfg.ports.ssh
      cfg.ports.http
      cfg.ports.https
    ]
    ++ (with cfg.ports.development; [
      common
      alternate
      additional
    ]);
  };

  # ============================================================================
  # DOCKER FOR SERVERS
  # ============================================================================
  virtualisation.docker = lib.mkIf (hostConfig.features.development or false) {
    enable = true;
    enableOnBoot = true;
    logDriver = "json-file";
    extraOptions = ''
      --log-opt max-size=10m
      --log-opt max-file=3
    '';
  };

  # ============================================================================
  # VS CODE SERVER COMPATIBILITY
  # ============================================================================
  programs.nix-ld = lib.mkIf (hostConfig.features.vscodeServer or false) {
    enable = true;
    libraries = with pkgs; [
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
}
