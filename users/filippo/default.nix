{ config, pkgs, lib, inputs, hostConfig, ... }:

let
  cfg = globalConfig;
  userCfg = cfg.users.filippo;
in
{
  # ============================================================================
  # USER DEFINITION
  # ============================================================================
  users.users.filippo = {
    isNormalUser = true;
    description = userCfg.description;
    shell = pkgs.zsh;
    
    # Gruppi dinamici basati su features dell'host
    extraGroups = userCfg.groups.base ++
      lib.optionals (hostConfig.features.desktop or false) userCfg.groups.desktop ++
      lib.optionals (hostConfig.features.development or false) userCfg.groups.development ++
      lib.optionals (hostConfig.features.gaming or false) userCfg.groups.gaming;
  };

  # ============================================================================
  # SUDO CONFIGURATION
  # ============================================================================
  security.sudo.wheelNeedsPassword = false;
}
