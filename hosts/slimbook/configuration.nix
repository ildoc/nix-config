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
  services.displayManager.sddm.theme = "breeze";
  
  # KDE Plasma wallpaper configuration
  system.activationScripts.setWallpaper = ''
    mkdir -p /etc/skel/.config
    cat > /etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc <<EOF
    [Containments][1][Wallpaper][org.kde.image][General]
    Image=/etc/nixos/assets/wallpapers/slimbook.jpg
    EOF
  '';
  
  # Copy wallpaper to system location
  environment.etc."wallpapers/slimbook.jpg".source = ../../assets/wallpapers/slimbook.jpg;
}
