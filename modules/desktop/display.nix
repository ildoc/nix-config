{ ... }:

{
  services.xserver = {
    enable = true;
    xkb = {
      layout = "it";
      variant = "";
      options = "numlock:on";
    };
  };
  
  services.desktopManager.plasma6.enable = true;
  
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
}
