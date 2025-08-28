{ config, pkgs, lib, inputs, hostConfig, ... }:

{
  # Boot configuration viene gestita nei profile
  # Questo file può contenere configurazioni boot comuni a tutti

  boot = {
    # Pulizia automatica /tmp
    tmp.cleanOnBoot = true;
    
    # Kernel modules comuni
    kernelModules = [ ];
    
    # Extra module packages se necessari
    extraModulePackages = [ ];
    
    # Inizializzazione
    initrd = {
      # Moduli sempre necessari
      availableKernelModules = [ ];
    };
  };
}
