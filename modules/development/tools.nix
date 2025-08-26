{ config, pkgs, ... }:

let
  isSlimbook = config.networking.hostName == "slimbook";
in
{
  environment.systemPackages = with pkgs; [
    # Databases
    postgresql
    sqlite
    
    # API tools
    postman
    curl
    httpie
    
    # Data processing
    jq
    yq
    kdiff3
    
    # Container tools
    docker
    docker-compose
    
  ] ++ (if isSlimbook then [
    unstable.jetbrains.rider
    vscode
  ] else []);
}
