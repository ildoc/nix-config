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
        
        # CRITICO: Disabilita COMPLETAMENTE USB autosuspend per evitare disconnessioni
        USB_AUTOSUSPEND = 0;
        USB_BLACKLIST_PHONE = 1;
        USB_BLACKLIST_WWAN = 1;
        
        # NUOVO: Disabilita Runtime PM su AC per evitare suspend delle porte
        RUNTIME_PM_ON_AC = "on";  # Cambiato da "auto" a "on" = disabilitato
        RUNTIME_PM_ON_BAT = "auto";
        
        # NUOVO: Blacklist dispositivi PCIe che non devono andare in suspend
        RUNTIME_PM_DRIVER_BLACKLIST = "nouveau nvidia amdgpu radeon";
        
        # AMD GPU - usa solo opzioni supportate
        RADEON_DPM_STATE_ON_AC = "performance";
        RADEON_DPM_STATE_ON_BAT = "battery";
        
        # NUOVO: Disabilita power management per dispositivi PCIe su AC
        PCIE_ASPM_ON_AC = "default";  # Non forzare power saving
        PCIE_ASPM_ON_BAT = "powersupersave";
        
        # Sound
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;
        
        # Disk
        DISK_IDLE_SECS_ON_AC = 0;
        DISK_IDLE_SECS_ON_BAT = 2;
        
        # NUOVO: Disabilita WiFi power saving su AC
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";
        
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
    # LOGIND - GESTIONE SEMPLIFICATA E COORDINATA
    # ============================================================================
    services.logind = {
      # Comportamento lid
      lidSwitch = "suspend";
      lidSwitchExternalPower = "lock";
      lidSwitchDocked = "ignore";

      extraConfig = ''
        # CRITICO: Disabilita COMPLETAMENTE idle action per evitare conflitti con KDE
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
    # WAKE-UP TRIGGERS - AGGIORNATO per gestire anche DisplayPort/USB-C
    # ============================================================================
    powerManagement.powerUpCommands = ''
      # Disabilita wake-up da USB (mouse/tastiera wireless)
      for device in /sys/bus/usb/devices/*/power/wakeup; do
        if [ -w "$device" ]; then
          echo disabled > "$device" 2>/dev/null || true
        fi
      done
      
      # NUOVO: Disabilita autosuspend per hub USB e porte con monitor
      for device in /sys/bus/usb/devices/*/power/autosuspend; do
        if [ -w "$device" ]; then
          echo -1 > "$device" 2>/dev/null || true
        fi
      done
      
      # NUOVO: Disabilita autosuspend per dispositivi USB-C/Thunderbolt
      for device in /sys/bus/thunderbolt/devices/*/power/control; do
        if [ -w "$device" ]; then
          echo on > "$device" 2>/dev/null || true
        fi
      done
    '';
    
    # NUOVO: Servizio per mantenere i monitor sempre attivi quando su AC
    systemd.services.prevent-monitor-suspend = {
      description = "Prevent external monitors from suspending";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Trova tutti i dispositivi drm (display)
        for card in /sys/class/drm/card*/device/power/control; do
          if [ -w "$card" ]; then
            echo on > "$card" 2>/dev/null || true
          fi
        done
        
        # Disabilita runtime PM per controller grafici AMD
        for amd in /sys/bus/pci/drivers/amdgpu/*/power/control; do
          if [ -w "$amd" ]; then
            echo on > "$amd" 2>/dev/null || true
          fi
        done
      '';
    };
  };
}
