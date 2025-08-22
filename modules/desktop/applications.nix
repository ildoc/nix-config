# modules/desktop/applications.nix
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
    spotify
    
    # Codec essenziali per podcast Spotify
    ffmpeg
    libvorbis
    
    # Games
    prismlauncher

    # KDE applications
    kdePackages.kate
    kdePackages.dolphin
    kdePackages.spectacle
    kdePackages.okular
    kdePackages.gwenview
    kdePackages.konsole

    # System utilities
    dconf-editor
    pkgs.nixfmt-rfc-style
  ];

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    khelpcenter
  ];
  
  # Aggiungi le variabili d'ambiente necessarie
  environment.variables = {
    # Forza Spotify a cercare ffmpeg nel PATH di sistema
    SPOTIFY_FFMPEG = "${pkgs.ffmpeg}/bin/ffmpeg";
  };
}
