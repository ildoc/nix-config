{ config, pkgs, lib, globalConfig, hostConfig, ... }:

let
  cfg = hostConfig.hardware;
  
  # Helper per determinare se abbiamo NVIDIA in qualsiasi forma
  hasNvidia = cfg.graphics.primary == "nvidia" || cfg.graphics.discrete == "nvidia";
  
  # Helper per determinare se abbiamo AMD graphics
  hasAmdGpu = cfg.graphics.primary == "amd" || cfg.graphics.discrete == "amd";
  
  # Helper per determinare la GPU Intel
  hasIntelGpu = cfg.graphics.primary == "intel";
  
  # Helper per determinare se siamo in VM
  isVirtual = cfg.graphics.primary == "virtual";
  
  # Costruisci i pacchetti graphics in base all'hardware
  graphicsPackages = with pkgs; 
    lib.optionals hasIntelGpu [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ] ++
    lib.optionals hasAmdGpu [
      mesa
      amdvlk
      rocmPackages.clr.icd
    ] ++
    lib.optionals (!isVirtual) [
      vaapiVdpau
      libvdpau-va-gl
    ] ++
    lib.optionals (hostConfig.features.gaming or false) [
      vulkan-loader
      vulkan-validation-layers
      vulkan-tools
    ] ++
    lib.optionals (hasAmdGpu && (hostConfig.features.development or false)) [
      rocmPackages.clr
      rocmPackages.clr.icd
    ] ++
    lib.optionals (hasIntelGpu && (hostConfig.features.development or false)) [
      intel-compute-runtime
    ];
    
  # Pacchetti 32-bit per gaming
  graphicsPackages32 = with pkgs.pkgsi686Linux;
    lib.optionals (hostConfig.features.gaming or false) (
      lib.optionals hasIntelGpu [
        intel-vaapi-driver
        vaapiVdpau
        libvdpau-va-gl
      ] ++
      lib.optionals hasAmdGpu [
        mesa
        amdvlk
      ]
    );
in
{
  config = {
    # ============================================================================
    # CPU MICROCODE UPDATES
    # ============================================================================
    hardware.cpu = lib.mkMerge [
      (lib.mkIf (cfg.cpu.vendor == "amd") {
        amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      })
      (lib.mkIf (cfg.cpu.vendor == "intel") {
        intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      })
    ];
    
    # ============================================================================
    # GRAPHICS CONFIGURATION
    # ============================================================================
    hardware.graphics = {
      enable = true;
      enable32Bit = lib.mkDefault (hostConfig.features.gaming or false);
      
      # Usa le liste pre-costruite
      extraPackages = graphicsPackages;
      extraPackages32 = graphicsPackages32;
    };
    
    # ============================================================================
    # NVIDIA CONFIGURATION
    # ============================================================================
    hardware.nvidia = lib.mkIf hasNvidia {
      modesetting.enable = true;
      
      # Power management per laptop con GPU discreta NVIDIA
      powerManagement = {
        enable = lib.mkDefault (hostConfig.type == "laptop" && cfg.graphics.discrete == "nvidia");
        finegrained = lib.mkDefault false;
      };
      
      # Driver aperto per GPU più recenti (serie 20xx+)
      open = lib.mkDefault false;
      
      nvidiaSettings = true;
      
      # Usa il driver stabile di default
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      
      # Prime sync per laptop con GPU ibrida
      prime = lib.mkIf (hostConfig.type == "laptop" && cfg.graphics.discrete == "nvidia") {
        sync.enable = lib.mkDefault false;  # Usa offload di default per batteria
        offload = {
          enable = lib.mkDefault true;
          enableOffloadCmd = true;
        };
        
        # Questi vanno configurati per-host se hai laptop con NVIDIA
        # intelBusId = "PCI:0:2:0";
        # nvidiaBusId = "PCI:1:0:0";
      };
    };
    
    # Aggiungi il driver video solo se abbiamo NVIDIA
    services.xserver.videoDrivers = lib.mkIf hasNvidia [ "nvidia" ];
    
    # ============================================================================
    # KERNEL CONFIGURATION
    # ============================================================================
    boot = {
      # Moduli kernel basati sull'hardware
      kernelModules = lib.mkMerge [
        (lib.optionals (cfg.cpu.vendor == "amd") [ "kvm-amd" ])
        (lib.optionals (cfg.cpu.vendor == "intel") [ "kvm-intel" ])
        (lib.optionals hasNvidia [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ])
      ];
      
      # Blacklist driver conflittuali per NVIDIA
      blacklistedKernelModules = lib.mkIf hasNvidia [ "nouveau" ];
      
      # Parametri kernel basati sull'hardware
      kernelParams = lib.mkMerge [
        # AMD GPU
        (lib.optionals hasAmdGpu [
          "amdgpu.ppfeaturemask=0xffffffff"  # Abilita tutte le features
        ])
        
        # NVIDIA
        (lib.optionals hasNvidia [
          "nvidia-drm.modeset=1"
        ])
        
        # Intel graphics
        (lib.optionals hasIntelGpu [
          "i915.enable_guc=2"
          "i915.enable_fbc=1"
        ])
      ];
    };
    
    # ============================================================================
    # ENVIRONMENT PACKAGES - Strumenti specifici per GPU
    # ============================================================================
    environment.systemPackages = with pkgs; lib.mkMerge [
      # Strumenti NVIDIA
      (lib.optionals hasNvidia [
        nvtopPackages.nvidia
        nvidia-vaapi-driver
      ])
      
      # Strumenti AMD
      (lib.optionals hasAmdGpu [
        radeontop
        lact  # AMD GPU control panel
      ])
      
      # Strumenti Intel
      (lib.optionals hasIntelGpu [
        intel-gpu-tools
      ])
      
      # Strumenti generici GPU (non per VM)
      (lib.optionals (!isVirtual && (hostConfig.features.desktop or false)) [
        glxinfo
        vulkan-tools
        gpu-viewer
      ])
    ];
  };
}
