{ config, pkgs, ... }:

{
  imports = [
    ./development/languages.nix
    ./development/tools.nix
    ./development/docker.nix
  ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  
  environment.variables = {
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
  };
}
