{ config, pkgs, ... }:

{
  # Configurazione desktop environment
  
  # X11 e desktop
  services.xserver = {
    enable = true;
    
    # Configurazione tastiera
    xkb = {
      layout = "it";
      variant = "";
    };
  };
  
  # KDE Plasma 6 (aggiornato da Plasma 5)
  services.desktopManager.plasma6.enable = true;
  
  # Display manager (separato da xserver)
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true; # Abilita Wayland per SDDM
    };
  };
  
  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Printing
  services.printing.enable = true;

  # NetworkManager
  networking.networkmanager.enable = true;
  users.users.filippo.extraGroups = [ "networkmanager" ];

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    font-awesome
    # Font per KDE
    source-code-pro
    source-sans-pro
  ];

  # Pacchetti desktop
  environment.systemPackages = with pkgs; [
    # Messaggistica
    telegram-desktop

    # Browser
    firefox
    
    # Editor di testo
    vscode
    
    # Multimedia
    vlc
    spotify
    
    # KDE utilities per Plasma 6
    kdePackages.kate # Editor di testo KDE
    kdePackages.dolphin # File manager KDE
    kdePackages.spectacle # Screenshot tool KDE
    kdePackages.okular # PDF viewer KDE
    kdePackages.gwenview # Image viewer KDE
    kdePackages.konsole # Terminal KDE
    
    # Utilities generiche
    dconf-editor
  ];

  # Configurazioni KDE Plasma 6
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    # Rimuovi app KDE non necessarie
    elisa # music player
    khelpcenter
  ];
  
  # Abilita alcune features KDE
  programs.kdeconnect.enable = true;

  # Spotify sync
  networking.firewall.allowedTCPPorts = [ 57621 ];
}
