{ config, pkgs, lib, globalConfig, hostConfig, ... }:

let
  cfg = globalConfig;
in
{
  # ============================================================================
  # CORE SYSTEM PACKAGES - Centralizzati e organizzati per tipologia
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # ============================================================================
    # ESSENTIALS - Strumenti di base sempre presenti
    # ============================================================================
    wget
    curl
    git
    htop
    tree
    lsof
    file
    which
    fastfetch
    unzip
    zip
    
    # ============================================================================
    # SECURITY & SECRETS
    # ============================================================================
    sops
    age
    
    # ============================================================================
    # HARDWARE & SYSTEM INFO
    # ============================================================================
    pciutils
    usbutils
    
    # ============================================================================
    # CONTAINER & ORCHESTRATION (se development è abilitato)
    # ============================================================================
  ] ++ lib.optionals (hostConfig.features.development or false) [
    kubectl
    docker-compose
  ] ++ lib.optionals (hostConfig.type == "laptop") [
    # ============================================================================
    # LAPTOP-SPECIFIC TOOLS
    # ============================================================================
    acpi
    powertop
    efibootmgr
  ] ++ lib.optionals (hostConfig.features.wireguard or false) [
    # ============================================================================
    # VPN TOOLS
    # ============================================================================
    wireguard-tools
  ];
  
  # ============================================================================
  # ALIASES GLOBALI - Centralizzati qui
  # ============================================================================
  environment.shellAliases = {    # FIX: era "eenvironment" con doppia 'e'
    # RIMOSSI: Git shortcuts (già in shell.nix)
    # RIMOSSI: System shortcuts base (già in shell.nix)
    
    # NixOS shortcuts specifici
    rebuild = "sudo nixos-rebuild switch --flake .";
    rebuild-test = "sudo nixos-rebuild test --flake .";
    nix-gc = "sudo nix-collect-garbage -d";
    nix-update = "sudo nix flake update";
    
    # System info
    sys-info = "fastfetch";
    
    # Process management
    psg = "ps aux | grep";
    
  } // lib.optionalAttrs (hostConfig.type == "laptop") {
    # LAPTOP-SPECIFIC ALIASES
    battery = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
    brightness-up = "light -A 10";
    brightness-down = "light -U 10";
    wifi-scan = "nmcli device wifi list";
    wifi-connect = "nmcli device wifi connect";
    power-status = "tlp-stat -s";
  } // lib.optionalAttrs (hostConfig.features.development or false) {
    # DEVELOPMENT ALIASES (solo quelli non in development/default.nix)
    k = "kubectl";
  };
}
