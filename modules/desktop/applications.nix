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
}
