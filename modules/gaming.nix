{ config, pkgs, ... }:

{
  # Configurazione gaming
  
  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Hardware accelerazione
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Pacchetti gaming
  environment.systemPackages = with pkgs; [
    # Gaming
    steam
    lutris
    heroic
    
    # Gaming utilities
    gamemode
    mangohud
    
    # Communication
    discord
    
    # Streaming/Recording
    obs-studio
    
    # Development
    vscode
  ];

  # Gaming optimizations
  programs.gamemode.enable = true;
  
  # Firewall per gaming
  networking.firewall = {
    allowedTCPPorts = [ 
      27036 # Steam Remote Play
      27037 # Steam Remote Play
    ];
    allowedUDPPorts = [
      27031 # Steam Remote Play
      27036 # Steam Remote Play
    ];
  };
}
