{ lib, ... }:

{
  options.myConfig = {
    # User configurations
    users = {
      filippo = {
        gitUserName = lib.mkOption {
          type = lib.types.str;
          default = "ildoc";
          description = "Git username for filippo";
        };
        
        gitUserEmail = lib.mkOption {
          type = lib.types.str;
          default = "il_doc@protonmail.com";
          description = "Git email for filippo";
        };
      };
    };
    
    # Host-specific configurations
    hosts = {
      slimbook = {
        wallpaper = lib.mkOption {
          type = lib.types.str;
          default = "slimbook.jpg";
          description = "Wallpaper filename for slimbook";
        };
      };
    };
  };
}
