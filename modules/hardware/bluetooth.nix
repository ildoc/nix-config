{ config, lib, inputs, globalConfig, hostConfig, ... }:

let
  hasBluetoothHW = hostConfig.hardware.hasBluetooth or false;
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
        };
      };
    };
    
    services.blueman.enable = true;
  };
}
