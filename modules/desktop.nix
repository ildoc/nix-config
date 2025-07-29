{ config, pkgs, ... }:

{
  # Configurazione desktop environment aggiornata per NixOS 25.05
  
  # X11 e desktop
  services.xserver = {
    enable = true;
    
    # Configurazione tastiera
    xkb = {
      layout = "it";
      variant = "";
      # Num Lock abilitato (integrato con xkb)
      options = "numlock:on";
    };
  };
  
  # KDE Plasma 6
  services.desktopManager.plasma6.enable = true;
  
  # Display manager
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
  
  # Audio con PipeWire (default su 25.05)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # NetworkManager
  networking.networkmanager.enable = true;
  users.users.filippo.extraGroups = [ "networkmanager" ];

  # Printing
  services.printing.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    font-awesome
    source-code-pro
    source-sans-pro
  ];

  # Pacchetti desktop essenziali
  environment.systemPackages = with pkgs; [
    # Browser e comunicazione
    firefox
    telegram-desktop

    # Editor
    vscode
    
    # Multimedia
    vlc
    spotify
    
    # KDE utilities per Plasma 6
    kdePackages.kate
    kdePackages.dolphin
    kdePackages.spectacle
    kdePackages.okular
    kdePackages.gwenview
    kdePackages.konsole
    
    # Utilities
    dconf-editor
  ];

  # Esclude app KDE non necessarie
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    khelpcenter
  ];
  
  # KDE features
  programs.kdeconnect.enable = true;

  # Firewall per KDE Connect
  networking.firewall.allowedTCPPorts = [ 1714 1715 1716 1717 1718 1719 1720 1721 1722 1723 1724 ];
  networking.firewall.allowedUDPPorts = [ 1714 1715 1716 1717 1718 1719 1720 1721 1722 1723 1724 ];
}
