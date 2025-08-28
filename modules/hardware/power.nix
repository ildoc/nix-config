{ config, lib, inputs, hostConfig, ... }:

let
  cfg = inputs.config;
  isLaptop = hostConfig.type == "laptop";
  hasBattery = hostConfig.hardware.hasBattery or false;
in
{
  # ============================================================================
  # POWER MANAGEMENT (LAPTOP ONLY)
  # ============================================================================
  config = lib.mkIf isLaptop {
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
        
        # CPU Frequency Limits
        CPU_SCALING_MIN_FREQ_ON_AC = 0;
        CPU_SCALING_MAX_FREQ_ON_AC = 0;
        CPU_SCALING_MIN_FREQ_ON_BAT = 0;
        CPU_SCALING_MAX_FREQ_ON_BAT = 2400000;
        
        # Battery Thresholds
        START_CHARGE_THRESH_BAT0 = lib.mkIf hasBattery 20;
        STOP_CHARGE_THRESH_BAT0 = lib.mkIf hasBattery 80;
        
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
    # LAPTOP HARDWARE FEATURES
    # ============================================================================
    programs.light.enable = true;
    services.thermald.enable = true;
    
    services.logind = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "lock";
      lidSwitchDocked = "ignore";
    };
    
    # ============================================================================
    # LAPTOP OPTIMIZATIONS
    # ============================================================================
    boot.kernel.sysctl = {
      "vm.laptop_mode" = 5;
    };
  };
}
