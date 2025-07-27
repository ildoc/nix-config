{ config, pkgs, ... }:

{
  # Configurazione gaming
  
  # Steam
  programs.steam = {
    enable = true;
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
}
