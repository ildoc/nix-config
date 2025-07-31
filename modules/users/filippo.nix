{ config, pkgs, lib, ... }:

{
  users.users.filippo = {
    isNormalUser = true;
    description = "Filippo";
    shell = pkgs.zsh;
    extraGroups = [ 
      "wheel"
    ] ++ lib.optionals config.networking.networkmanager.enable [
      "networkmanager"
    ] ++ lib.optionals config.virtualisation.docker.enable [
      "docker"
    ] ++ lib.optionals config.services.xserver.enable [
      "video"
    ];
  };
}
