{ config, pkgs, lib, inputs, hostConfig, ... }:

{
  imports = [
    ./base.nix
    ../modules/desktop
  ];

  # ============================================================================
  # LAPTOP-SPECIFIC BOOT CONFIGURATION
  # ============================================================================
  boot = {
    # Boot loader ottimizzato per laptop con dual boot
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        editor = false;
        consoleMode = "max";
      };
      
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      
      timeout = 5;
    };
    
    # Compressione initrd per risparmiare spazio
    initrd = {
      compressor = "zstd";
      compressorArgs = ["-19" "-T0"];
    };
    
    # Kernel parameters per laptop
    kernelParams = [
      "quiet"
      "splash"
      # Risparmio energetico
      "i915.enable_fbc=1"
      "i915.enable_psr=2"
    ];
  };

  # ============================================================================
  # POWER MANAGEMENT
  # ============================================================================
  services.power-profiles-daemon.enable = false;
  
  services.tlp = {
    enable = true;
    settings = {
      # CPU Governor
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      # Energy Performance
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      
      # Turbo Boost
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      
      # CPU Frequency Limits (0 = no limit)
      CPU_SCALING_MIN_FREQ_ON_AC = 0;
      CPU_SCALING_MAX_FREQ_ON_AC = 0;
      CPU_SCALING_MIN_FREQ_ON_BAT = 0;
      CPU_SCALING_MAX_FREQ_ON_BAT = 2400000;
      
      # Battery Thresholds
      START_CHARGE_THRESH_BAT0 = lib.mkIf (hostConfig.hardware.hasBattery or false) 20;
      STOP_CHARGE_THRESH_BAT0 = lib.mkIf (hostConfig.hardware.hasBattery or false) 80;
      
      # USB Power
      USB_AUTOSUSPEND = 1;
      USB_BLACKLIST_PHONE = 1;
      USB_AUTOSUSPEND_DISABLE_ON_SHUTDOWN = 1;
      
      # PCIe Power
      PCIE_ASPM_ON_AC = "performance";
      PCIE_ASPM_ON_BAT = "powersupersave";
      
      # Runtime PM
      RUNTIME_PM_ON_AC = "off";
      RUNTIME_PM_ON_BAT = "on";
      
      # WiFi Power
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      
      # Sound Power Saving
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;
      
      # Disk APM
      DISK_APM_LEVEL_ON_AC = "255 255";
      DISK_APM_LEVEL_ON_BAT = "128 128";
      
      # SATA Link Power
      SATA_LINKPWR_ON_AC = "max_performance";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
    };
  };

  # ============================================================================
  # HARDWARE FEATURES
  # ============================================================================
  
  # Backlight control
  programs.light.enable = true;
  
  # Thermal management
  services.thermald.enable = true;
  
  # Lid behavior
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
    lidSwitchDocked = "ignore";
  };

  # ============================================================================
  # NETWORK
  # ============================================================================
  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
        powersave = true;
      };
      
      plugins = with pkgs; [
        networkmanager-openvpn
        networkmanager-l2tp
      ];
    };
    
    # Hostname from config
    hostName = hostConfig.description or "laptop";
  };

  # ============================================================================
  # LAPTOP OPTIMIZATIONS
  # ============================================================================
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.laptop_mode" = 5;
  };

  # ============================================================================
  # LAPTOP-SPECIFIC PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Power management
    acpi
    powertop
    
    # Network tools
    wireguard-tools
    
    # Boot utilities
    efibootmgr
  ] ++ lib.optionals (hostConfig.features.development or false) [
    # Development tools specifici per laptop
    insomnia
    obsidian
    libreoffice
  ];

  # ============================================================================
  # LAPTOP ALIASES
  # ============================================================================
  environment.shellAliases = {
    battery = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
    brightness-up = "light -A 10";
    brightness-down = "light -U 10";
    wifi-scan = "nmcli device wifi list";
    wifi-connect = "nmcli device wifi connect";
  };
}
