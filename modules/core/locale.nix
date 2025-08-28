{ config, lib, inputs, ... }:

let
  cfg = inputs.config;
in
{
  time.timeZone = cfg.system.timezone;
  
  i18n = {
    defaultLocale = cfg.system.locale.default;
    extraLocaleSettings = cfg.system.locale.settings;
    supportedLocales = [
      "${cfg.system.locale.default}/UTF-8"
      "${cfg.system.locale.extra}/UTF-8"
    ];
  };

  console = {
    useXkbConfig = true;
  };
  
  # Numlock è gestito nel desktop module per sistemi con GUI
}
