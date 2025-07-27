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
      
      DEVICES_TO_DISABLE_ON_STARTUP = "wwan";
      DEVICES_TO_ENABLE_ON_STARTUP = "wifi";
    };
  };
  
  # Configurazione Bluetooth con fix firmware
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
        DiscoverableTimeout = 0;
        PairableTimeout = 0;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };
  
  # Firmware completo per Bluetooth
  hardware.enableRedistributableFirmware = true;
  
  # Fix specifico per btusb e firmware loading
  boot.extraModprobeConfig = ''
    # Disabilita autosuspend per btusb
    options btusb enable_autosuspend=0
    # Forza il reset del controller all'avvio
    options btusb reset=1
  '';
  
  # Assicurati che i moduli siano caricati nell'ordine corretto
  boot.kernelModules = [ "btusb" ];
  
  # Blueman
  services.blueman.enable = true;
  
  # Servizio systemd personalizzato per inizializzazione Bluetooth
  systemd.services.bluetooth-init = {
    description = "Initialize Bluetooth Controller";
    after = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Aspetta che il servizio bluetooth sia pronto
      sleep 2
      
      # Forza l'inizializzazione del controller
      ${pkgs.bluez}/bin/bluetoothctl power on || true
      
      # Aspetta e riprova se necessario
      sleep 1
      ${pkgs.bluez}/bin/bluetoothctl power on || true
    '';
  };
  
  # Pacchetti Bluetooth
  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
  ];
  
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
  
  # Gruppi aggiuntivi per l'utente filippo (bluetooth e video)
  users.users.filippo.extraGroups = [ "bluetooth" "video" ];
  
  # Num Lock abilitato all'avvio
  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.numlockx}/bin/numlockx on
  '';
  
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
