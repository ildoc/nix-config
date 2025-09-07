{ config, pkgs, lib, globalConfig, hostConfig, ... }:

let
  cfg = globalConfig;
in
{
  imports = [
    ../modules/core
  ];

  # ============================================================================
  # SYSTEM CONFIGURATION
  # ============================================================================
  system.stateVersion = cfg.system.stateVersion;
  
  # ============================================================================
  # FIX CRITICI PER REBUILD
  # ============================================================================
  
  # Previeni restart di servizi critici durante switch
  systemd.services = {
    # Servizi di sistema che non devono essere riavviati
    accounts-daemon.restartIfChanged = false;
    nix-daemon.restartIfChanged = false;
    systemd-logind.restartIfChanged = false;
    NetworkManager.restartIfChanged = false;
    
    # TLP - reload invece di restart
    tlp = lib.mkIf (hostConfig.type == "laptop") {
      restartIfChanged = false;
      reloadIfChanged = true;
    };
    
    # Bluetooth - non riavviare se attivo
    bluetooth.restartIfChanged = false;
  };
  
  # Disabilita accounts-daemon per KDE (non necessario)
  services.accounts-daemon.enable = lib.mkForce false;
  
  # ============================================================================
  # BOOT OPTIMIZATIONS
  # ============================================================================
  boot = {
    # Kernel più recente per migliori performance
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    
    # Blacklist moduli non necessari
    blacklistedKernelModules = [ 
      "pcspkr"  # Beep fastidioso
    ] ++ lib.optionals (hostConfig.type != "server") [
      "iTCO_wdt"  # Watchdog non necessario su desktop/laptop
    ];
    
    # Supporto per filesystem
    supportedFilesystems = [ "ntfs" "exfat" ];
    
    # Cleanup /tmp all'avvio
    tmp.cleanOnBoot = true;
    
    # Loader timeout ridotto
    loader.timeout = lib.mkDefault 3;
  };
  
  # ============================================================================
  # SYSTEMD OPTIMIZATIONS
  # ============================================================================
  systemd = {
    # Servizi da mascherare (disabilitare completamente)
    services = {
      # Disabilita servizi non necessari
      systemd-networkd.enable = lib.mkDefault false; # Usiamo NetworkManager
    };
    
    # Timeout più aggressivi per boot più veloce
    extraConfig = ''
      DefaultTimeoutStartSec=30s
      DefaultTimeoutStopSec=10s
      DefaultRestartSec=1s
    '';
    
    # Watchdog disabilitato su laptop/desktop
    watchdog = lib.mkIf (hostConfig.type != "server") {
      device = null;
    };
  };
  
  # ============================================================================
  # PERFORMANCE TUNING
  # ============================================================================
  # Zram swap per migliori performance
  zramSwap = lib.mkIf (hostConfig.type != "server") {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # Usa fino al 50% della RAM per zram
  };
  
  # ============================================================================
  # SICUREZZA OTTIMIZZATA
  # ============================================================================
  security = {
    # Abilita polkit
    polkit.enable = true;
    
    # AppArmor per sicurezza aggiuntiva (opzionale)
    apparmor = {
      enable = lib.mkDefault false; # Abilita se vuoi più sicurezza
    };
    
    # Limiti risorse più generosi per utenti wheel
    pam.loginLimits = [
      {
        domain = "@wheel";
        type = "soft";
        item = "nofile";
        value = "524288";
      }
      {
        domain = "@wheel";
        type = "hard";
        item = "nofile";
        value = "1048576";
      }
    ];
  };
  
  # ============================================================================
  # SERVIZI BASE OTTIMIZZATI
  # ============================================================================
  services = {
    # Abilita dbus
    dbus = {
      enable = true;
      packages = [ pkgs.dconf ];
    };
    
    # Abilita fstrim per SSD
    fstrim = {
      enable = true;
      interval = "weekly";
    };
    
    # Abilita earlyoom per prevenire freeze da OOM
    earlyoom = {
      enable = true;
      freeMemThreshold = 5; # Inizia a killare processi al 5% di RAM libera
      freeSwapThreshold = 10;
      enableNotifications = true;
    };
    
    # Journald ottimizzato
    journald = {
      extraConfig = ''
        SystemMaxUse=1G
        SystemMaxFileSize=100M
        MaxRetentionSec=1month
        ForwardToSyslog=no
      '';
    };
  };
  
  # ============================================================================
  # ENVIRONMENT
  # ============================================================================
  environment = {
    # Variabili d'ambiente globali
    variables = {
      NIXPKGS_ALLOW_UNFREE = "1";
      MOZ_USE_XINPUT2 = "1"; # Migliore supporto touchpad in Firefox
    };
    
    # Path di sistema
    systemPackages = [ pkgs.coreutils ];
  };
  
  programs.dconf.enable = true;
}
