{ config, pkgs, lib, inputs, globalConfig, hostConfig, ... }:

let
  cfg = globalConfig;
in
{
  imports = [
    ./fonts.nix
    ./packages.nix  # Pacchetti centralizzati
  ];

  # ============================================================================
  # DISPLAY SERVER
  # ============================================================================
  services.xserver = {
    enable = true;
    xkb = {
      layout = "it";
      variant = "";
      options = "numlock:on";
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
  # NETWORKING FOR DESKTOP - NetworkManager è configurato nei profili specifici
  # ============================================================================
  # networking.networkmanager.enable = true;  # Spostato nei profili

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
  # BLUETOOTH (se presente)
  # ============================================================================
  hardware.bluetooth = lib.mkIf (hostConfig.hardware.hasBluetooth or false) {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  services.blueman.enable = lib.mkIf (hostConfig.hardware.hasBluetooth or false) true;

  # ============================================================================
  # KDE CONNECT
  # ============================================================================
  programs.kdeconnect.enable = true;
  
  networking.firewall = {
    allowedTCPPorts = cfg.ports.kde.connect;
    allowedUDPPorts = cfg.ports.kde.connect;
  };

  # ============================================================================
  # DESKTOP PACKAGES - Ora gestiti in ./packages.nix
  # ============================================================================
  # I pacchetti desktop sono centralizzati nel modulo packages.nix

  # ============================================================================
  # NUMLOCK ON STARTUP
  # ============================================================================
  systemd.services.numlock-on = lib.mkIf (hostConfig.type != "server") {
    description = "Enable NumLock on startup";
    wantedBy = [ "graphical.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.numlockx}/bin/numlockx on";
      StandardInput = "tty";
      TTYPath = "/dev/tty1";
    };
  };
}
