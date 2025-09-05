{ config, lib, pkgs, inputs, globalConfig, hostConfig, ... }:

let
  hasBluetoothHW = hostConfig.hardware.hasBluetooth or false;
  isDesktop = hostConfig.features.desktop or false;
  # Rileva se stiamo usando KDE Plasma
  isPlasma = config.services.desktopManager.plasma6.enable or false;
in
{
  config = lib.mkIf hasBluetoothHW {
    # ============================================================================
    # BLUETOOTH CONFIGURATION
    # ============================================================================
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
          # Migliora la compatibilità con dispositivi moderni
          FastConnectable = true;
        };
        
        # Aggiungi policy per auto-switch audio
        Policy = {
          AutoEnable = true;
        };
      };
    };
    
    # ============================================================================
    # BLUETOOTH MANAGER
    # ============================================================================
    # Usa Blueman SOLO se NON siamo in KDE Plasma
    # KDE ha il suo bluetooth manager integrato (bluedevil)
    services.blueman.enable = isDesktop && !isPlasma;
    
    # ============================================================================
    # BLUETOOTH PACKAGES
    # ============================================================================
    environment.systemPackages = with pkgs; lib.optionals isDesktop (
      if isPlasma then [
        # KDE usa bluedevil (già incluso in plasma6)
        kdePackages.bluedevil
      ] else [
        # Altri DE usano blueman
        blueman
      ]
    );
  };
}
