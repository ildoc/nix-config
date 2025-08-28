{ config, pkgs, lib, inputs, hostConfig, ... }:

let
  cfg = inputs.config;
in
{
  imports = [
    ./applications.nix
    ./fonts.nix
    # KDE sarà importato dal profile se necessario
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
  # NETWORKING FOR DESKTOP
  # ============================================================================
  networking.networkmanager.enable = true;

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
  # DESKTOP ENVIRONMENT VARIABLES
  # ============================================================================
  environment.sessionVariables = {
    QT_STYLE_OVERRIDE = "breeze";
    BROWSER = "firefox";
  };

  # ============================================================================
  # KDE CONNECT
  # ============================================================================
  programs.kdeconnect.enable = true;
  
  networking.firewall = {
    allowedTCPPorts = cfg.ports.kde.connect;
    allowedUDPPorts = cfg.ports.kde.connect;
  };

  # ============================================================================
  # DESKTOP PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; 
    cfg.packages.desktop.core ++
    cfg.packages.desktop.kde ++ [
      # Desktop utilities
      dconf-editor
      nixfmt-rfc-style
      
      # Multimedia
      vlc
      unstable.spotify
      
      # Communication
      firefox
      telegram-desktop
    ] ++ lib.optionals (hostConfig.features.gaming or false) [
      prismlauncher
    ];

  # ============================================================================
  # EXCLUDE UNWANTED KDE PACKAGES
  # ============================================================================
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    khelpcenter
    kate
  ];

  # ============================================================================
  # FONTS CONFIGURATION
  # ============================================================================
  fonts = {
    enableDefaultPackages = true;
    
    packages = with pkgs; [
      # System fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      
      # Nerd Fonts
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      
      # Additional fonts
      fira
      fira-code
      source-code-pro
      source-sans-pro
      font-awesome
      
      # Microsoft compatible
      corefonts
      vistafonts
    ];
    
    fontconfig = {
      enable = true;
      
      defaultFonts = {
        serif = [ "Noto Serif" "Liberation Serif" ];
        sansSerif = [ "Noto Sans" "Liberation Sans" ];
        monospace = [ "FiraCode Nerd Font" "JetBrainsMono Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
      
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
