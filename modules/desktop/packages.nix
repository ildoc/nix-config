{ config, pkgs, lib, globalConfig, hostConfig, ... }:

let
  cfg = globalConfig;
in
{
  # ============================================================================
  # DESKTOP PACKAGES CENTRALIZZATI
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # ============================================================================
    # CORE DESKTOP APPLICATIONS - Sempre presenti su desktop
    # ============================================================================
    firefox
    telegram-desktop
    vlc
    vscode
    
    # ============================================================================
    # MULTIMEDIA
    # ============================================================================
    unstable.spotify
    
    # ============================================================================
    # KDE APPLICATIONS SUITE (Solo essenziali)
    # ============================================================================
    kdePackages.dolphin
    kdePackages.spectacle
    kdePackages.okular
    kdePackages.gwenview
    kdePackages.konsole
    kdePackages.ark
    
    # ============================================================================
    # DESKTOP UTILITIES
    # ============================================================================
    nixfmt-rfc-style
    
    # ============================================================================
    # CONDITIONAL PACKAGES BASED ON FEATURES
    # ============================================================================
  ] ++ lib.optionals (hostConfig.features.gaming or false) [
    # Gaming applications
    steam
    lutris
    heroic
    gamemode
    discord
    obs-studio
  ] ++ lib.optionals (hostConfig.features.development or false) [
    # Development GUI tools
    dbeaver-bin
    postman
  ];

  # ============================================================================
  # EXCLUDE UNWANTED KDE PACKAGES
  # ============================================================================
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa          # Music player (usiamo Spotify)
    khelpcenter    # Help center
    kate           # Text editor (usiamo VS Code)
    plasma-browser-integration  # Non necessario se non usi integrazione browser
  ];
}
