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
  
  # Power management semplificato per laptop
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      # Configurazione minimale ma efficace
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      # Batteria
      START_CHARGE_THRESH_BAT0 = 20;
      STOP_CHARGE_THRESH_BAT0 = 80;
      
      # USB autosuspend
      USB_AUTOSUSPEND = 1;
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
  
  # Firmware completo
  hardware.enableRedistributableFirmware = true;
  
  # Backlight control
  programs.light.enable = true;
  
  # Gruppi aggiuntivi per l'utente
  users.users.filippo.extraGroups = [ "video" ];
  
  # Thermal management
  services.thermald.enable = true;
  
  # Suspend on lid close
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };
  
  # Ottimizzazioni per laptop (moderate)
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };
}
