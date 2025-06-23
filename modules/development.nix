{ config, pkgs, ... }:

{
  # Strumenti di sviluppo
  
  environment.systemPackages = with pkgs; [
    # Linguaggi di programmazione
    nodejs_20
    python3
    python3Packages.pip
    go
    rustc
    cargo
    
    # Database
    postgresql
    sqlite
    
    # Build tools
    gnumake
    cmake
    gcc
    
    # Version control
    git
    
    # Network tools
    postman
    
    # Container tools (su tutti gli host development)
    docker
    docker-compose
    
  ] ++ (if config.networking.hostName != "dev-server" then [
    # IDE - solo su laptop/desktop
    (if config.networking.hostName == "work-laptop" then [
      unstable.jetbrains.rider
      vscode
    ] else if config.networking.hostName == "gaming-rig" then [
      vscode
    ] else [])
  ] else []);

  # Docker su tutti gli host che usano development module
  virtualisation.docker = {
    enable = true;  # Abilita sempre quando c'è development
    enableOnBoot = true;
  };
  
  # Aggiungi filippo al gruppo docker
  users.users.filippo.extraGroups = [ "docker" ];
}
