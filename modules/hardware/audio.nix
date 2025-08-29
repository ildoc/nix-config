{ config, lib, globalConfig, inputs, hostConfig, ... }:

let
  cfg = globalConfig;
  isGaming = hostConfig.features.gaming or false;
in
{
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
    
    # Gaming optimizations
    extraConfig.pipewire = lib.mkIf isGaming {
      "92-low-latency" = {
        context.properties = {
          default.clock.rate = cfg.gaming.audio.sampleRate;
          default.clock.quantum = cfg.gaming.audio.quantum;
          default.clock.min-quantum = cfg.gaming.audio.quantum;
          default.clock.max-quantum = cfg.gaming.audio.quantum;
        };
      };
    };
  };
}
