{ config, pkgs, ... }:

{
  # Strumenti di sviluppo
  
  environment.systemPackages = with pkgs; [
    # Linguaggi di programmazione
    nodejs_20
    python3
    python3Packages.pip
    go
    
    # .NET development (disponibile su tutti gli host development)
    dotnet-sdk_8
    
    # Database tools
    postgresql
    sqlite
    
    # Build tools
    gnumake
    cmake
    gcc
    
    # Network/API tools
    postman
    curl
    httpie
    
    # Container tools
    docker
    docker-compose
    
    # Development utilities
    jq
    yq
    
  ] ++ (
    # IDE - condizionale per host
    if config.networking.hostName == "slimbook" then [
      unstable.jetbrains.rider
      vscode
    ] else if config.networking.hostName == "gaming" then [
      vscode
    ] else []
  );

  # Docker configuration
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
  
  # Aggiungi filippo al gruppo docker
  users.users.filippo.extraGroups = [ "docker" ];
  
  # Development environment variables
  environment.variables = {
    # Per development
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
  };
}
