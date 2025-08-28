{ config, pkgs, lib, inputs, hostConfig, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ============================================================================
  # HOST-SPECIFIC SETTINGS
  # ============================================================================
  networking.hostName = "slimbook";

  # ============================================================================
  # HARDWARE SPECIFICS
  # ============================================================================
  # CPU microcode updates
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  
  # Graphics configuration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  
  hardware.enableRedistributableFirmware = true;

  # ============================================================================
  # WIREGUARD CONFIGURATION
  # ============================================================================
  # Usa la configurazione centralizzata
  myConfig.vpn = hostConfig.vpn;

  # ============================================================================
  # SLIMBOOK-SPECIFIC PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; 
    hostConfig.applications.additional ++ [
      # Aggiungi qui eventuali pacchetti specifici solo per questo slimbook
      unstable.jetbrains.rider
      teams-for-linux
    ];

  # ============================================================================
  # BOOT CONFIGURATION (se diverso dal default del profile)
  # ============================================================================
  # Solo se hai bisogno di override specifici per questo host
  # boot.loader.timeout = 10;
  
  # ============================================================================
  # CUSTOM SERVICES
  # ============================================================================
  # Eventuali servizi specifici per questo laptop
  
  # ============================================================================
  # DUAL BOOT SUPPORT (se presente)
  # ============================================================================
  # Se hai Windows in dual boot, decommenta:
  # boot.loader.systemd-boot.extraEntries = {
  #   "windows.conf" = ''
  #     title Windows 11
  #     efi /EFI/Microsoft/Boot/bootmgfw.efi.original
  #     sort-key z_windows
  #   '';
  # };
}
