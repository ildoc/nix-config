{ pkgs, ... }:

{
  fonts = {
    # Abilita il supporto font
    enableDefaultPackages = true;
    
    # Pacchetti font
    packages = with pkgs; [
      # System fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      
      # Free fonts
      liberation_ttf
      
      # Nerd Fonts
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      
      # Fonts aggiuntivi
      fira
      fira-code
      source-code-pro
      source-sans-pro
      
      # Icons
      font-awesome
      
      # Microsoft compatible fonts
      corefonts
      vistafonts
    ];
    
    # Configurazione font di default del sistema
    fontconfig = {
      enable = true;
      
      defaultFonts = {
        serif = [ "Noto Serif" "Liberation Serif" ];
        sansSerif = [ "Noto Sans" "Liberation Sans" ];
        monospace = [ "FiraCode Nerd Font" "JetBrainsMono Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
      
      # Miglioramenti rendering
      antialias = true;
      hinting = {
        enable = true;
        style = "slight";
      };
      
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };
    };
  };
}
