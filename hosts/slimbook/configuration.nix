{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "slimbook";

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Power management per laptop con configurazione intelligente
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      # CPU Governor - Performance su AC, risparmio su batteria
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # CPU Performance - Massime prestazioni su AC
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

      # Intel P-state - Turbo sempre attivo su AC
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # Frequenze CPU - Nessun limite su AC
      CPU_SCALING_MIN_FREQ_ON_AC = 0;
      CPU_SCALING_MAX_FREQ_ON_AC = 0;
      CPU_SCALING_MIN_FREQ_ON_BAT = 0;
      CPU_SCALING_MAX_FREQ_ON_BAT = 2400000;

      # Battery thresholds
      START_CHARGE_THRESH_BAT0 = 20;
      STOP_CHARGE_THRESH_BAT0 = 80;

      # USB - Nessun autosuspend su AC
      USB_AUTOSUSPEND = 1;
      USB_BLACKLIST_PHONE = 1;
      USB_AUTOSUSPEND_DISABLE_ON_SHUTDOWN = 1;

      # PCIe - Massime prestazioni su AC
      PCIE_ASPM_ON_AC = "performance";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # Runtime PM - Disabilitato su AC per massime prestazioni
      RUNTIME_PM_ON_AC = "off";
      RUNTIME_PM_ON_BAT = "on";

      # WiFi power saving - Disabilitato su AC
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # Sound power saving - Disabilitato su AC
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;

      # Disk APM - Massime prestazioni su AC
      DISK_APM_LEVEL_ON_AC = "255 255";
      DISK_APM_LEVEL_ON_BAT = "128 128";

      # SATA Link Power Management - Massime prestazioni su AC
      SATA_LINKPWR_ON_AC = "max_performance";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";

      # Intel GPU - Massime prestazioni su AC
      INTEL_GPU_MIN_FREQ_ON_AC = 0;
      INTEL_GPU_MIN_FREQ_ON_BAT = 0;
      INTEL_GPU_MAX_FREQ_ON_AC = 0;
      INTEL_GPU_MAX_FREQ_ON_BAT = 0;
      INTEL_GPU_BOOST_FREQ_ON_AC = 0;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 0;
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
    };
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  hardware.enableRedistributableFirmware = true;

  # Backlight control
  programs.light.enable = true;

  # Thermal management
  services.thermald.enable = true;

  # Suspend on lid close
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };

  # Laptop optimizations
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  # Slimbook specific packages
  environment.systemPackages = with pkgs; [
    # Battery management
    acpi
    powertop

    # Development tools specific to slimbook
    unstable.jetbrains.rider
    insomnia # Alternative to Postman

    # Productivity
    obsidian
    libreoffice

    teams-for-linux

    # VPN tools
    wireguard-tools
  ];

  # WireGuard support in NetworkManager
  networking.networkmanager = {
    enable = true; # Already enabled in desktop module, but being explicit
    plugins = with pkgs; [
      networkmanager-openvpn
      networkmanager-l2tp
    ];
  };

  # Enable WireGuard kernel module
  boot.kernelModules = [ "wireguard" ];
}
