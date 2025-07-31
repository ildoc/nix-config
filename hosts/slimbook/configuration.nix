{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "slimbook";
  
  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Power management for laptop
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      # Battery thresholds
      START_CHARGE_THRESH_BAT0 = 20;
      STOP_CHARGE_THRESH_BAT0 = 80;
      
      USB_AUTOSUSPEND = 1;
    };
  };
  
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
    };
  };
  
  hardware.enableRedistributableFirmware = true;
  
  # Backlight control
  programs.light.enable = true;
  
  # Thermal management
  services.thermald.enable = true;
  
  # Suspend on lid close
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
  };
  
  # Laptop optimizations
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };
  
  # Slimbook specific packages
  environment.systemPackages = with pkgs; [
    # Battery management
    acpi
    powertop
    
    # Development tools specific to slimbook
    unstable.jetbrains.rider
    insomnia  # Alternative to Postman
    
    # Productivity
    obsidian
    libreoffice
  ];
  
  # Custom wallpaper for slimbook
  # Copy wallpaper to system location
  environment.etc."wallpapers/slimbook.jpg".source = ../../assets/wallpapers/slimbook.jpg;
  
  # Set wallpaper via systemd service for user
  systemd.user.services.set-wallpaper = {
    description = "Set custom wallpaper";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "set-wallpaper" ''
        # Wait for Plasma to start
        sleep 5
        
        # Set wallpaper using Plasma's D-Bus interface
        ${pkgs.libsForQt5.qttools.bin}/bin/qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
          var allDesktops = desktops();
          for (i = 0; i < allDesktops.length; i++) {
            d = allDesktops[i];
            d.wallpaperPlugin = "org.kde.image";
            d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");
            d.writeConfig("Image", "file:///etc/wallpapers/slimbook.jpg");
          }
        '
      ''}";
      RemainAfterExit = true;
    };
  };
}
