{ config, pkgs, ... }:
{
  services.xserver = {
    enable = true;
    xkb = {
      layout = "it";
      variant = "";
      options = "numlock:on";
    };
  };
  
  services.desktopManager.plasma6 = {
    enable = true;
  };
  
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      
      # Tema Breeze Dark per SDDM
      settings = {
        Theme = {
          Current = "breeze";
          CursorTheme = "breeze_cursors";
        };
      };
    };
    
    # Auto-login (opzionale, decommentare se desiderato)
    # autoLogin = {
    #   enable = true;
    #   user = "filippo";
    # };
  };
  
  # Configurazioni globali KDE Plasma
  programs.dconf.enable = true;
  
  # Script per configurare il tema e le impostazioni di sistema
  environment.systemPackages = with pkgs; [
    (writeScriptBin "configure-kde-theme" ''
      #!${stdenv.shell}
      # Script eseguito dopo il login per configurare il tema
      
      # Configura Breeze Dark
      kwriteconfig6 --file kdeglobals --group General --key ColorScheme BreezeDark
      kwriteconfig6 --file kdeglobals --group General --key Name Breeze
      kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage org.kde.breezedark.desktop
      
      # Configura il tema delle icone
      kwriteconfig6 --file kdeglobals --group Icons --key Theme breeze-dark
      
      # Configura il tema del cursore
      kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme breeze_cursors
      
      # Applica le impostazioni
      qdbus org.kde.KWin /KWin reconfigure || true
    '')
  ];
  
  # Configurazione sistema per tema scuro
  environment.sessionVariables = {
    QT_STYLE_OVERRIDE = "breeze";
  };
}
