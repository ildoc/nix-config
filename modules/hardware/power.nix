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
  # ============================================================================
  # POWER MANAGEMENT (LAPTOP ONLY)
  # ============================================================================
  config = lib.mkIf isLaptop {
    # Disabilita power-profiles-daemon (conflitto con TLP)
    services.power-profiles-daemon.enable = false;

    services.tlp = {
      enable = true;
      settings = {
        # ============================================================================
        # FIX PRINCIPALE: Rimuovi opzioni che possono causare blocchi
        # ============================================================================
        
        # CPU - Mantieni semplice
        CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        
        # IMPORTANTE: Usa valori numerici corretti per USB_AUTOSUSPEND
        USB_AUTOSUSPEND = 0;  # Disabilita completamente
        
        # AMD Graphics - Rimuovi opzioni che potrebbero non esistere sul tuo hardware
        # Commenta queste se causano problemi:
        # RADEON_DPM_STATE_ON_AC = "performance";
        # RADEON_DPM_STATE_ON_BAT = "battery";
        # RADEON_POWER_PROFILE_ON_AC = "default";
        # RADEON_POWER_PROFILE_ON_BAT = "low";
        
        # Runtime PM - Usa stringhe corrette
        RUNTIME_PM_ON_AC = "off";
        RUNTIME_PM_ON_BAT = "off";
        
        # Sound power save
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 0;
        
        # NVMe/SATA - Rimuovi se causano problemi
        # AHCI_RUNTIME_PM_ON_AC = "off";
        # AHCI_RUNTIME_PM_ON_BAT = "off";
        
        # Aggiungi START_CHARGE_THRESH e STOP_CHARGE_THRESH se supportati
        # START_CHARGE_THRESH_BAT0 = 75;
        # STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    # ============================================================================
    # FIX: Assicura che TLP non venga riavviato durante rebuild
    # ============================================================================
    systemd.services.tlp = {
      restartIfChanged = false;
      reloadIfChanged = true;
    };

    # ============================================================================
    # LAPTOP HARDWARE FEATURES
    # ============================================================================
    programs.light.enable = true;
    services.thermald.enable = lib.mkDefault false; # Disabilita se causa conflitti con AMD

    # Configurazioni Logind
    services.logind = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "lock";
      lidSwitchDocked = "ignore";

      extraConfig = ''
        # Timeout per idle (in secondi)
        IdleAction=lock
        IdleActionSec=1800

        # Gestione tasti power
        HandlePowerKey=poweroff
        HandlePowerKeyLongPress=reboot
        HandleSuspendKey=suspend
        HandleHibernateKey=hibernate

        # Non ignorare gli inibitori del lid switch
        LidSwitchIgnoreInhibited=no
      '';
    };

    # ============================================================================
    # LAPTOP OPTIMIZATIONS
    # ============================================================================
    boot.kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.laptop_mode" = 5;
    };
  };
}
