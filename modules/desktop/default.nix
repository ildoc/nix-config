{ config, pkgs, lib, inputs, globalConfig, hostConfig, ... }:

let
  cfg = globalConfig;
in
{
  imports = [
    ./fonts.nix
    ./packages.nix  # Pacchetti centralizzati
    ../hardware/bluetooth.nix
  ];

  # ============================================================================
  # DISPLAY SERVER
  # ============================================================================
  services.xserver = {
    enable = true;
    xkb = {
      layout = "it";
      variant = "";
    };
  };

  # ============================================================================
  # DESKTOP MANAGER
  # ============================================================================
  services.desktopManager.plasma6.enable = true;
  
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      
      settings = {
        Theme = {
          Current = "breeze";
          CursorTheme = cfg.desktop.theme.cursor.theme;
        };
      };
    };
  };

  # ============================================================================
  # DESKTOP ENVIRONMENT VARIABLES
  # ============================================================================
  environment.sessionVariables = {
    QT_STYLE_OVERRIDE = "breeze";
    BROWSER = "firefox";
  };

  # ============================================================================
  # PRINTING
  # ============================================================================
  services.printing.enable = true;

  # ============================================================================
  # AUDIO SYSTEM
  # ============================================================================
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = lib.mkDefault false;
  };

  # ============================================================================
  # HARDWARE ACCELERATION
  # ============================================================================
  hardware.graphics = {
    enable = true;
    enable32Bit = lib.mkIf (hostConfig.features.gaming or false) true;
  };

  # ============================================================================
  # KDE CONNECT
  # ============================================================================
  programs.kdeconnect.enable = true;
  
  networking.firewall = {
    allowedTCPPorts = cfg.ports.kde.connect;
    allowedUDPPorts = cfg.ports.kde.connect;
  };

}
