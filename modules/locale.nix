{ config, lib, ... }:

{
  time.timeZone = "Europe/Rome";
  
  i18n = {
    defaultLocale = "it_IT.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "it_IT.UTF-8";
      LC_IDENTIFICATION = "it_IT.UTF-8";
      LC_MEASUREMENT = "it_IT.UTF-8";
      LC_MONETARY = "it_IT.UTF-8";
      LC_NAME = "it_IT.UTF-8";
      LC_NUMERIC = "it_IT.UTF-8";
      LC_PAPER = "it_IT.UTF-8";
      LC_TELEPHONE = "it_IT.UTF-8";
      LC_TIME = "it_IT.UTF-8";
    };
  };

  console = {
    useXkbConfig = true;
  };
  
  services.xserver.xkb.options = lib.mkIf (config.services.xserver.enable) "numlock:on";
}
