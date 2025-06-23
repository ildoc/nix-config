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
    gh # GitHub CLI
    
    # Network tools
    postman
    
    # Containers (solo per laptop/desktop, non server)
  ] ++ (if config.networking.hostName != "dev-server" then [
    # IDE - solo su laptop/desktop
    (if config.networking.hostName == "work-laptop" then [
      unstable.jetbrains.rider
      vscode
    ] else if config.networking.hostName == "gaming-rig" then [
      vscode
    ] else [])
  ] else []);

  # Docker solo per sviluppo locale (non server)
  virtualisation.docker = {
    enable = (config.networking.hostName != "dev-server");
    enableOnBoot = true;
  };
  
  users.users.filippo.extraGroups = 
    if config.networking.hostName != "dev-server" 
    then [ "docker" ] 
    else [];
}
