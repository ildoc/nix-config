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
    # KDE APPLICATIONS SUITE
    # ============================================================================
    kdePackages.dolphin
    kdePackages.spectacle
    kdePackages.okular
    kdePackages.gwenview
    kdePackages.konsole
    kdePackages.kcalc
    kdePackages.yakuake
    kdePackages.ark
    
    # ============================================================================
    # DESKTOP UTILITIES
    # ============================================================================
    dconf-editor
    nixfmt-rfc-style
    
    # ============================================================================
    # CONDITIONAL PACKAGES BASED ON FEATURES
    # ============================================================================
  ] ++ lib.optionals (hostConfig.features.gaming or false) [
    # Gaming applications
    prismlauncher
    steam
    lutris
    heroic
    gamemode
  ] ++ lib.optionals (hostConfig.features.development or false) [
    # Development GUI tools
    unstable.jetbrains.rider
    unstable.jetbrains.datagrip
  ] ++ lib.optionals (hostConfig.features.wireguard or false) [
    # VPN GUI clients
    kdePackages.kdeconnect-kde
  ];

  # ============================================================================
  # EXCLUDE UNWANTED KDE PACKAGES
  # ============================================================================
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa          # Music player (usiamo Spotify)
    khelpcenter    # Help center
    kate           # Text editor (usiamo VS Code)
    kwrited        # KWrite daemon (kwrite non esiste più in Plasma 6)
    plasma-browser-integration  # Non necessario se non usi Chrome/Firefox con integrazione
  ];
}
