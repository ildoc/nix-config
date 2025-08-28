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
        
        # NOTA: gitUserEmail è ora gestito tramite sops-nix
        # Il valore reale viene letto da secrets/secrets.yaml
      };
    };
  };
  
  # Set default values
  config = {
    myConfig = {
      users.filippo = {
        gitUserName = lib.mkDefault "ildoc";
        # gitUserEmail viene ora da sops secrets
      };
    };
  };
}
