{ config, pkgs, lib, ... }:

{
  # Configurazione Power Devil (gestione energetica KDE)
  services.upower.enable = true;
  
  # Configurazioni di sistema per la gestione energetica
  powerManagement = {
    enable = true;
    # Abilita la sospensione
    powertop.enable = false; # Disabilitato per evitare conflitti con TLP
  };
  
  # Script per configurare Power Devil
  environment.systemPackages = with pkgs; [
    (writeScriptBin "configure-kde-power" ''
      #!${stdenv.shell}
      # Configurazione Power Devil per tutti i profili
      
      # Profilo AC (Corrente)
      kwriteconfig6 --file powermanagementprofilesrc --group AC --group DPMSControl --key idleTime 1800
      kwriteconfig6 --file powermanagementprofilesrc --group AC --group DPMSControl --key lockBeforeTurnOff 0
      kwriteconfig6 --file powermanagementprofilesrc --group AC --group SuspendSession --key idleTime 3600
      kwriteconfig6 --file powermanagementprofilesrc --group AC --group SuspendSession --key suspendType 1
      
      # Profilo Battery (Batteria)
      kwriteconfig6 --file powermanagementprofilesrc --group Battery --group DPMSControl --key idleTime 1800
      kwriteconfig6 --file powermanagementprofilesrc --group Battery --group DPMSControl --key lockBeforeTurnOff 0
      kwriteconfig6 --file powermanagementprofilesrc --group Battery --group SuspendSession --key idleTime 3600
      kwriteconfig6 --file powermanagementprofilesrc --group Battery --group SuspendSession --key suspendType 1
      
      # Profilo LowBattery (Batteria scarica)
      kwriteconfig6 --file powermanagementprofilesrc --group LowBattery --group DPMSControl --key idleTime 600
      kwriteconfig6 --file powermanagementprofilesrc --group LowBattery --group SuspendSession --key idleTime 900
      kwriteconfig6 --file powermanagementprofilesrc --group LowBattery --group SuspendSession --key suspendType 1
      
      echo "Power management configured successfully!"
    '')
  ];
  
  # Servizio systemd per applicare le configurazioni al login
  systemd.user.services.kde-initial-config = {
    description = "Configure KDE theme and power settings";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 5 && configure-kde-theme && configure-kde-power'";
      RemainAfterExit = true;
    };
  };
}
