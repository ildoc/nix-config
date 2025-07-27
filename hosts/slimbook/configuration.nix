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
  
  # ======================================
  # Configurazione Bluetooth con firmware completo
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
    };
  };
  
  # Firmware completo - MOLTO IMPORTANTE
  hardware.enableRedistributableFirmware = true;
  
  # Pacchetti firmware aggiuntivi
  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
    # Firmware aggiuntivi
    linux-firmware
  ];
  
  # Fix modprobe per btusb
  boot.extraModprobeConfig = ''
    # Disabilita autosuspend
    options btusb enable_autosuspend=0
    # Forza reset
    options btusb reset=1
    # Debug per vedere cosa succede
    options btusb dyndbg=+p
  '';
  
  # Assicurati che tutti i moduli BT siano disponibili
  boot.kernelModules = [ "btusb" "btrtl" "btintel" "btbcm" "btmtk" ];
  
  # Servizio personalizzato per forzare l'inizializzazione
  systemd.services.bluetooth-controller-init = {
    description = "Force Bluetooth Controller Initialization";
    after = [ "bluetooth.service" "sys-subsystem-bluetooth-devices-hci0.device" ];
    wants = [ "sys-subsystem-bluetooth-devices-hci0.device" ];
    wantedBy = [ "bluetooth.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5s";
    };
    script = ''
      # Aspetta che il dispositivo sia disponibile
      for i in {1..30}; do
        if [ -e /sys/class/bluetooth/hci0 ]; then
          echo "Controller hci0 trovato"
          break
        fi
        echo "Aspettando controller hci0... tentativo $i"
        sleep 1
      done
      
      # Usa hciconfig per forzare l'attivazione
      if command -v hciconfig >/dev/null 2>&1; then
        echo "Attivando controller con hciconfig..."
        hciconfig hci0 up || true
        sleep 2
        hciconfig hci0 reset || true
        sleep 2
        hciconfig hci0 up || true
      fi
      
      # Usa bluetoothctl come backup
      echo "Attivando controller con bluetoothctl..."
      ${pkgs.bluez}/bin/bluetoothctl power on || true
      sleep 2
      ${pkgs.bluez}/bin/bluetoothctl power off || true
      sleep 1
      ${pkgs.bluez}/bin/bluetoothctl power on || true
    '';
  };

  # Blueman
  services.blueman.enable = true;

  # ======================================
  
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
