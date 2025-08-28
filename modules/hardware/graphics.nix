{ config, pkgs, lib, inputs, hostConfig, ... }:

let
  gpuType = hostConfig.hardware.graphics or "intel";
  isGaming = hostConfig.features.gaming or false;
in
{
  # ============================================================================
  # HARDWARE ACCELERATION
  # ============================================================================
  hardware.graphics = {
    enable = true;
    enable32Bit = lib.mkIf isGaming true;
    
    extraPackages = with pkgs; 
      # Intel graphics
      lib.optionals (gpuType == "intel") [
        intel-media-driver
        intel-vaapi-driver
        vaapiVdpau
        libvdpau-va-gl
      ] 
      # AMD graphics
      ++ lib.optionals (gpuType == "amd") [
        mesa
        amdvlk
      ]
      # NVIDIA graphics  
      ++ lib.optionals (gpuType == "nvidia") [
        # NVIDIA drivers vengono gestiti separatamente
      ];
  };

  # ============================================================================
  # NVIDIA CONFIGURATION
  # ============================================================================
  hardware.nvidia = lib.mkIf (gpuType == "nvidia") {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false; # Usa driver proprietari
    nvidiaSettings = true;
    
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.xserver.videoDrivers = lib.mkIf (gpuType == "nvidia") [ "nvidia" ];
}
