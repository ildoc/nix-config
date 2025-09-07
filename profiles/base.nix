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
  # FIX CRITICI - PREVIENI RESTART DI SERVIZI DURANTE SWITCH
  # ============================================================================
  
  systemd.services = {
    # Servizi core che non devono MAI essere riavviati durante switch
    accounts-daemon.restartIfChanged = false;
    nix-daemon.restartIfChanged = false;
    systemd-logind.restartIfChanged = false;
    NetworkManager.restartIfChanged = false;
    
    # CRITICAL FIX: Previeni restart di journald e polkit
    systemd-journald.restartIfChanged = false;
    systemd-journald.stopIfChanged = false;
    polkit.restartIfChanged = false;
    polkit.stopIfChanged = false;
    
    # Dbus non deve essere riavviato
    dbus.restartIfChanged = false;
    dbus.reloadIfChanged = true;
    
    # Timer che non devono essere riavviati
    nix-gc.restartIfChanged = false;
    nix-optimise.restartIfChanged = false;
    
    # TLP - solo reload
    tlp = lib.mkIf (hostConfig.type == "laptop") {
      restartIfChanged = false;
      reloadIfChanged = true;
      stopIfChanged = false;
    };
    
    # Bluetooth
    bluetooth.restartIfChanged = false;
    
    # SOPS services
    sops-nix.restartIfChanged = false;
    setup-git-config.restartIfChanged = false;
    setup-ssh-keys.restartIfChanged = false;
  };
  
  # ============================================================================
  # SYSTEMD SWITCH CONFIGURATION
  # ============================================================================
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      if [[ -e /run/current-system ]]; then
        echo "=== Skipping service restarts for critical services ==="
        ${pkgs.nix}/bin/nix store diff-closures /run/current-system "$systemConfig" || true
      fi
    '';
  };
  
  # ============================================================================
  # SWITCH CONFIGURATION - Usa switch-to-configuration più sicuro
  # ============================================================================
  system.switch = {
    enable = true;
    enableNg = false; # Disabilita il nuovo switch che può causare problemi
  };
  
  # ============================================================================
  # JOURNALD - Configurazione che non richiede restart
  # ============================================================================
  services.journald = {
    # Usa configurazione di default per evitare restart
    extraConfig = lib.mkForce "";
  };
  
  # ============================================================================
  # POLKIT - Configurazione stabile
  # ============================================================================
  security.polkit = {
    enable = true;
    # Non aggiungere regole extra che richiederebbero restart
    extraConfig = lib.mkForce "";
  };
  
  # ============================================================================
  # NIX DAEMON - Configurazione stabile
  # ============================================================================
  nix.daemonCPUSchedPolicy = lib.mkForce "batch";
  nix.daemonIOSchedClass = lib.mkForce "idle";
  
  # ============================================================================
  # ALTRI FIX
  # ============================================================================
  
  # Disabilita accounts-daemon per KDE (non necessario)
  services.accounts-daemon.enable = lib.mkForce false;
  
  # Assicura che dbus sia configurato correttamente
  services.dbus = {
    enable = true;
    packages = [ pkgs.dconf ];
  };
  
  programs.dconf.enable = true;
  
  # ============================================================================
  # BOOT CONFIGURATION
  # ============================================================================
  boot = {
    # Kernel più stabile
    kernelPackages = lib.mkDefault pkgs.linuxPackages;
    
    # Cleanup /tmp all'avvio
    tmp.cleanOnBoot = true;
  };
}
