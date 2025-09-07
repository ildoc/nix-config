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
  
  # FIX: Previeni restart di servizi critici durante switch
  systemd.services = {
    accounts-daemon.restartIfChanged = false;
    nix-daemon.restartIfChanged = false;  # AGGIUNGI QUESTA
    systemd-logind.restartIfChanged = false;  # E QUESTA
  };
  
  # Disabilita accounts-daemon completamente per KDE
  services.accounts-daemon.enable = lib.mkForce false;
  
  # Assicura che dbus sia configurato correttamente
  services.dbus = {
    enable = true;
    packages = [ pkgs.dconf ];
  };
  
  programs.dconf.enable = true;
}
