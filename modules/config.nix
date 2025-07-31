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
  };
  
  # Set default values
  config = {
    myConfig = {
      users.filippo = {
        gitUserName = lib.mkDefault "ildoc";
        gitUserEmail = lib.mkDefault "il_doc@protonmail.com";
      };
    };
  };
}
