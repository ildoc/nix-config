{ config, pkgs, lib, inputs, globalConfig, hostConfig, ... }:

let
  isEnabled = hostConfig.features.vscodeServer or false;
in
{
  config = lib.mkIf isEnabled {
    # ============================================================================
    # VS CODE SERVER
    # ============================================================================
    services.vscode-server.enable = true;
    
    # ============================================================================
    # NIX-LD FOR COMPATIBILITY
    # ============================================================================
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        fuse3
        icu
        nss
        openssl
        curl
        expat
      ];
    };
    
    # ============================================================================
    # DEVELOPMENT ENVIRONMENT
    # ============================================================================
    environment.variables = {
      EDITOR = "nano";
      VISUAL = "nano";
      KUBE_EDITOR = "nano";
    };
    
    # ============================================================================
    # FIREWALL
    # ============================================================================
    networking.firewall.allowedTCPPorts = [ 
      # VS Code server ports
      # Le porte vengono aperte dinamicamente dal servizio
    ];
  };
}
