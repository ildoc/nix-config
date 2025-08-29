{ config, lib, globalConfig, ... }:

let
  cfg = globalConfig;
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
}
