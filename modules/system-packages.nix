{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # Network tools
    wget
    curl
    nmap
    tcpdump
    
    # System utilities
    htop
    tree
    lsof
    strace
    file
    which
    fastfetch
    
    # Archives
    unzip
    zip
    
    # Version control
    git
    
    # Hardware info
    pciutils
    usbutils
    
    # Container tools
    kubectl
    
  ] ++ lib.optionals config.services.xserver.enable [
    numlockx
  ];
}
