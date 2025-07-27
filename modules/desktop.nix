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
    
    # KDE Plasma
    desktopManager.plasma5.enable = true;
  };
  
  # Display manager (separato da xserver)
  services.displayManager.sddm.enable = true;
  
  # Audio
  sound.enable = true;
  hardware.pulseaudio.enable = false;
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
    noto-fonts-cjk
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
    # Browser
    firefox
    
    # Editor di testo
    vscode
    
    # Multimedia
    vlc
    spotify
    
    # KDE utilities (Konsole è già incluso in KDE)
    kate # Editor di testo KDE
    dolphin # File manager KDE
    spectacle # Screenshot tool KDE
    okular # PDF viewer KDE
    gwenview # Image viewer KDE
    
    # Utilities generiche
    gnome.dconf-editor
  ];

  # Configurazioni KDE specifiche (nuova sintassi)
  environment.plasma5.excludePackages = with pkgs.libsForQt5; [
    # Rimuovi app KDE non necessarie
    elisa # music player
    khelpcenter
  ];
  
  # Abilita alcune features KDE
  programs.kdeconnect.enable = true;

  # Spotify sync
  networking.firewall.allowedTCPPorts = [ 57621 ];
}
