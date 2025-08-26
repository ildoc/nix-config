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
  
  # RIMOSSO: Script configure-kde-theme perché ora usiamo Plasma Manager
  
  # Configurazione sistema per tema scuro
  environment.sessionVariables = {
    QT_STYLE_OVERRIDE = "breeze";
  };
}
