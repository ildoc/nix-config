{ config, pkgs, lib, ... }:

let
  # Definisci i wallpapers per ogni host
  wallpapers = {
    slimbook = ../../assets/wallpapers/slimbook.jpg;
    gaming = ../../assets/wallpapers/gaming.jpg;  # Aggiungi quando hai il file
    # dev-server non ha bisogno di wallpaper
  };
  
  # Wallpaper corrente basato sull'hostname
  currentWallpaper = wallpapers.${config.networking.hostName} or null;
  
  # Abilita stylix solo su sistemi con GUI
  enableStylix = config.services.xserver.enable && currentWallpaper != null;
in
{
  stylix = lib.mkIf enableStylix {
    enable = true;
    
    # Usa il wallpaper specifico dell'host
    image = currentWallpaper;
    
    # Polarity - "dark" per tema scuro, "light" per tema chiaro
    polarity = "dark";
    
    # Schema colori - puoi usare "auto" per generarlo dal wallpaper
    # o uno schema predefinito
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    # Alternatives:
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
    
    # Configurazione fonts
    fonts = {
      monospace = {
        package = pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; };
        name = "FiraCode Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
      
      sizes = {
        applications = 11;
        desktop = 10;
        popups = 11;
        terminal = 12;
      };
    };
    
    # Opacità finestre
    opacity = {
      applications = 1.0;
      desktop = 1.0;
      popups = 1.0;
      terminal = 0.95;
    };
    
    # Configurazione cursore
    cursor = {
      package = pkgs.breeze-qt5;  # Usa Breeze per consistenza con KDE
      name = "breeze_cursors";
      size = 24;
    };
    
    # Target da configurare
    targets = {
      chromium.enable = false;  # Disabilita se preferisci tema di Chrome
      console.enable = true;
      grub.enable = false;  # Hai systemd-boot
      gtk.enable = true;
      gnome.enable = false;  # Disabilita esplicitamente GNOME
      kde.enable = true;  # Importante per Plasma
      nixvim.enable = false;  # Se usi neovim
    };
  };
  
  # Font packages extra per applicazioni
  fonts.packages = lib.mkIf enableStylix (with pkgs; [
    noto-fonts-cjk-sans  # Supporto caratteri asiatici
    liberation_ttf       # Compatibilità documenti MS
    (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
  ]);
}
