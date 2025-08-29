{ config, pkgs, lib, inputs, globalConfig, hostConfig, ... }:

{
  imports = [
    ./base.nix
    ../modules/desktop
  ];

  # ============================================================================
  # DESKTOP-SPECIFIC BOOT CONFIGURATION
  # ============================================================================
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        editor = false;
      };
      
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      
      timeout = 5;
    };
    
    # Desktop non ha bisogno di compressione estrema
    initrd = {
      compressor = "zstd";
      compressorArgs = ["-3"];
    };
    
    # Kernel parameters per desktop
    kernelParams = [
      "quiet"
      "splash"
    ];
  };

  # ============================================================================
  # HARDWARE FEATURES
  # ============================================================================
  # Thermal management (se presente)
  services.thermald.enable = lib.mkDefault true;

  # ============================================================================
  # NETWORK
  # ============================================================================
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = lib.mkDefault "wpa_supplicant";
    };
    
    # Hostname from config
    hostName = hostConfig.description or "desktop";
  };

  # ============================================================================
  # DESKTOP OPTIMIZATIONS
  # ============================================================================
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  # ============================================================================
  # POWER MANAGEMENT
  # ============================================================================
  # Desktop non ha bisogno di risparmio energetico aggressivo
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "performance";
  };
  
  services.power-profiles-daemon.enable = false;

  # ============================================================================
  # DESKTOP-SPECIFIC PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # System utilities
    efibootmgr
  ];
}
