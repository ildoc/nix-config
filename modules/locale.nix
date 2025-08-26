{ config, lib, ... }:

{
  time.timeZone = "Europe/Rome";
  
  i18n = {
    # Sistema in inglese
    defaultLocale = "en_US.UTF-8";
    
    # Formati italiani per numeri, date, valuta, ecc.
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
      # Mantieni messaggi in inglese
      LC_MESSAGES = "en_US.UTF-8";
      LANG = "en_US.UTF-8";
      LANGUAGE = "en_US";
    };
    
    # Assicurati che entrambi i locale siano generati
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "it_IT.UTF-8/UTF-8"
    ];
  };

  console = {
    useXkbConfig = true;
  };
  
  services.xserver.xkb.options = lib.mkIf (config.services.xserver.enable) "numlock:on";
}
