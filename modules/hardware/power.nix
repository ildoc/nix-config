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
        # Per CPU AMD Ryzen su Slimbook
        CPU_SCALING_GOVERNOR_ON_AC = "schedutil"; # Meglio di "performance" per AMD
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        # IMPORTANTE: Disabilita completamente USB autosuspend
        USB_AUTOSUSPEND = 0;
        USB_BLACKLIST = "0bda:*"; # Aggiungi per Realtek devices

        # Fix per AMD Graphics
        RADEON_DPM_STATE_ON_AC = "performance";
        RADEON_DPM_STATE_ON_BAT = "battery";
        RADEON_POWER_PROFILE_ON_AC = "default";
        RADEON_POWER_PROFILE_ON_BAT = "low";

        # Disabilita TUTTI i power saving che causano problemi
        RUNTIME_PM_ON_AC = "off";
        RUNTIME_PM_ON_BAT = "off";
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 0;

        # Per NVMe SSD
        AHCI_RUNTIME_PM_ON_AC = "off";
        AHCI_RUNTIME_PM_ON_BAT = "off";
      };
    };

    # ============================================================================
    # LAPTOP HARDWARE FEATURES
    # ============================================================================
    programs.light.enable = true;
    services.thermald.enable = true;

    # Configurazioni Logind - CORRETTE per NixOS
    services.logind = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "lock";
      lidSwitchDocked = "ignore";

      # Opzioni extraConfig per configurazioni aggiuntive
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
