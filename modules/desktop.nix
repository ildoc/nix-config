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
    
    # GNOME
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  
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
  services.blueman.enable = true;

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
  ];

  # Pacchetti desktop
  environment.systemPackages = with pkgs; [
    # Browser
    firefox
    
    # File manager
    nautilus
    
    # Editor di testo
    gedit
    
    # Multimedia
    vlc
    
    # Utilities
    gnome.gnome-tweaks
    dconf-editor
    
    # Terminal
    alacritty
  ];

  # Exclude some GNOME packages
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
  ]) ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-music
    epiphany # web browser
    geary # email reader
    gnome-characters
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
  ]);
}
