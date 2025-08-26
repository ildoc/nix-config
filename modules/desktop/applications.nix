{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Communication
    firefox
    telegram-desktop

    # Development
    vscode

    # Multimedia
    vlc
    
    # Usa Spotify da unstable che potrebbe avere fix più recenti
    unstable.spotify
    
    # Games
    prismlauncher

    # KDE applications
    kdePackages.dolphin
    kdePackages.spectacle
    kdePackages.okular
    kdePackages.gwenview
    kdePackages.konsole
    kdePackages.kcalc

    # System utilities
    dconf-editor
    pkgs.nixfmt-rfc-style
  ];

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    khelpcenter
    kate
  ];
}
