{
  config,
  lib,
  inputs,
  globalConfig,
  hostConfig,
  ...
}:

let
  cfg = globalConfig;
  isLaptop = hostConfig.type == "laptop";
  hasBattery = hostConfig.hardware.hasBattery or false;
in
{
  config = lib.mkIf isLaptop {
    # Disabilita power-profiles-daemon
    services.power-profiles-daemon.enable = false;

    services.tlp = {
      enable = true;
      settings = {
        # CPU
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        
        # Disabilita COMPLETAMENTE USB autosuspend (causa problemi)
        USB_AUTOSUSPEND = 0;
        
        # Runtime PM - lascia a "auto" ma monitora
        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";
        
        # AMD GPU - usa solo opzioni supportate
        RADEON_DPM_STATE_ON_AC = "performance";
        RADEON_DPM_STATE_ON_BAT = "battery";
        
        # Sound
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;
        
        # Disk
        DISK_IDLE_SECS_ON_AC = 0;
        DISK_IDLE_SECS_ON_BAT = 2;
        
        # Batteria (se supportato dal tuo laptop)
        # START_CHARGE_THRESH_BAT0 = 75;
        # STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    # CRITICO: Non riavviare TLP durante rebuild
    systemd.services.tlp = {
      restartIfChanged = false;
      reloadIfChanged = true;
    };

    # Luminosità
    programs.light.enable = true;
    
    # Disabilita thermald per AMD (causa conflitti)
    services.thermald.enable = false;

    # ============================================================================
    # LOGIND - GESTIONE SEMPLIFICATA
    # ============================================================================
    services.logind = {
      # Comportamento lid
      lidSwitch = "suspend";
      lidSwitchExternalPower = "lock";
      lidSwitchDocked = "ignore";

      extraConfig = ''
        # TIMEOUT IDLE - aumentato per evitare conflitti con KDE
        IdleAction=ignore
        IdleActionSec=0
        
        # Gestione tasti power
        HandlePowerKey=poweroff
        HandlePowerKeyLongPress=reboot
        HandleSuspendKey=suspend
        HandleHibernateKey=ignore
        
        # CRITICO: Rispetta gli inibitori di KDE
        HandleLidSwitch=suspend
        HandleLidSwitchExternalPower=lock
        HandleLidSwitchDocked=ignore
        LidSwitchIgnoreInhibited=yes
        IdleActionIgnoreInhibited=yes
      '';
    };

    # ============================================================================
    # LAPTOP OPTIMIZATIONS
    # ============================================================================
    boot.kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.laptop_mode" = 5;
      "vm.dirty_writeback_centisecs" = 1500;
    };
    
    # ============================================================================
    # WAKE-UP TRIGGERS - Previeni wake-up indesiderati
    # ============================================================================
    powerManagement.powerUpCommands = ''
      # Disabilita wake-up da USB (mouse/tastiera wireless)
      for device in /sys/bus/usb/devices/*/power/wakeup; do
        if [ -w "$device" ]; then
          echo disabled > "$device" 2>/dev/null || true
        fi
      done
    '';
  };
}
