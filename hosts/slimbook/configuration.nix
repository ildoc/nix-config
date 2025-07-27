{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Configurazioni specifiche per slimbook
  networking.hostName = "slimbook";
  
  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Disabilita power-profiles-daemon per evitare conflitto con TLP
  services.power-profiles-daemon.enable = false;
  
  # Power management ottimizzato per laptop
  services.tlp = {
    enable = true;
    settings = {
      # CPU
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      
      # Batteria
      START_CHARGE_THRESH_BAT0 = 20;
      STOP_CHARGE_THRESH_BAT0 = 80;
      
      # USB
      USB_AUTOSUSPEND = 1;
      
      # Audio
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;
      
      # Network
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      
      # Dischi
      DISK_IDLE_SECS_ON_AC = 0;
      DISK_IDLE_SECS_ON_BAT = 2;
    };
  };
  
  # Bluetooth ottimizzato
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # Risparmia batteria
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
  services.blueman.enable = true;
  
  # Touchpad con gestures
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
      middleEmulation = true;
      disableWhileTyping = true;
    };
  };
  
  # Backlight control
  programs.light.enable = true;
  users.users.filippo.extraGroups = [ "video" ];
  
  # Thermal management
  services.thermald.enable = true;
  
  # Suspend on lid close
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };
  
  # Ottimizzazioni per laptop
  boot.kernel.sysctl = {
    # Migliora la responsività
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    # Riduce i wakeup del disco
    "vm.dirty_expire_centisecs" = 6000;
    "vm.dirty_writeback_centisecs" = 6000;
  };
}
