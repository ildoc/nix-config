{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    # System fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    
    # Free fonts
    liberation_ttf
    
    # Development fonts
    fira-code
    fira-code-symbols
    source-code-pro
    source-sans-pro
    
    # Icons
    font-awesome
  ];
}
