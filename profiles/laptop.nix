{ config, pkgs, lib, inputs, globalConfig, hostConfig, ... }:

{
  imports = [
    ./base.nix
    ../modules/desktop
    ../modules/hardware/power.nix
  ];

  # ============================================================================
  # LAPTOP-SPECIFIC BOOT CONFIGURATION
  # ============================================================================
  boot = {
    # Boot loader ottimizzato per laptop con dual boot
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        editor = false;
        consoleMode = "max";
      };
      
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      
      timeout = 5;
    };
    
    # Compressione initrd per risparmiare spazio
    initrd = {
      compressor = "zstd";
      compressorArgs = ["-19" "-T0"];
    };
    
    # Kernel parameters per laptop
    kernelParams = [
      "quiet"
      "splash"
      # Risparmio energetico
      "i915.enable_fbc=1"
      "i915.enable_psr=2"
    ];
  };

  # ============================================================================
  # POWER MANAGEMENT - Già importato dal modulo hardware/power.nix sopra
  # ============================================================================
  # Il modulo hardware/power.nix gestisce tutta la configurazione power management
  
  # ============================================================================
  # HARDWARE FEATURES - Gestito dal modulo hardware/power.nix
  # ============================================================================
  
  # ============================================================================
  # NETWORK - Configurazione specifica per laptop
  # ============================================================================
  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
        powersave = true;
      };
      
      plugins = with pkgs; [
        networkmanager-openvpn
        networkmanager-l2tp
      ];
    };
  };

  # ============================================================================
  # LAPTOP-SPECIFIC PACKAGES - I pacchetti base sono gestiti da core/packages.nix
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Networking plugins già inclusi sopra in networkmanager.plugins
  ] ++ lib.optionals (hostConfig.features.development or false) [
    # Development tools specifici per laptop che richiedono GUI
    insomnia
    obsidian
    libreoffice
  ];

  # ============================================================================
  # LAPTOP ALIASES - Ora gestiti da core/packages.nix
  # ============================================================================
  # Gli alias sono centralizzati in modules/core/packages.nix
}
