{ config, pkgs, lib, ... }:

let
  # Definisci i wallpapers per ogni host
  wallpapers = {
    slimbook = ../../assets/wallpapers/slimbook.jpg;
    gaming = ../../assets/wallpapers/gaming.jpg;
  };
  
  # Wallpaper corrente basato sull'hostname
  currentWallpaper = wallpapers.${config.networking.hostName} or null;
  
  # Abilita stylix solo su sistemi con GUI e wallpaper disponibile
  enableStylix = config.services.xserver.enable && currentWallpaper != null;
in
{
  # Configurazione Stylix solo se abilitata
  config = lib.mkIf enableStylix {
    stylix = {
      enable = true;
      
      # Wallpaper specifico per host
      image = currentWallpaper;
      
      # Tema scuro
      polarity = "dark";
      
      # Schema colori Catppuccin Mocha
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      
      # Configurazione fonts
      fonts = {
        serif = {
          package = pkgs.noto-fonts;
          name = "Noto Serif";
        };
        sansSerif = {
          package = pkgs.noto-fonts;
          name = "Noto Sans";
        };
        monospace = {
          package = pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; };
          name = "FiraCode Nerd Font Mono";
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
      
      # Opacità
      opacity = {
        applications = 1.0;
        desktop = 1.0;
        popups = 1.0;
        terminal = 0.95;
      };
      
      # Cursore
      cursor = {
        package = pkgs.breeze-qt5;
        name = "breeze_cursors";
        size = 24;
      };
    };
    
    # Font packages aggiuntivi
    fonts.packages = with pkgs; [
      noto-fonts-cjk-sans
      liberation_ttf
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
    ];
  };
}
