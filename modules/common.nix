{ config, pkgs, ... }:

{
  # Configurazioni di base comuni a tutti gli host
  
  # Locale e timezone
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "it_IT.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };

  # Configurazione tastiera
  console = {
    keyMap = "it";
    useXkbConfig = true;
  };

  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Programmi essenziali
  programs = {
    zsh.enable = true;
    git.enable = true;
    vim.defaultEditor = true;
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # Pacchetti di base
  environment.systemPackages = with pkgs; [
    # Strumenti di base
    wget
    curl
    git
    vim
    htop
    tree
    unzip
    zip
    
    # Network tools
    nmap
    tcpdump
    
    # System tools
    lsof
    strace
    file
    which
  ];

  # Configurazione utente filippo
  users.users.filippo = {
    isNormalUser = true;
    description = "Filippo";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  # Sudo senza password per wheel
  security.sudo.wheelNeedsPassword = false;

  # Sistema stabile
  system.stateVersion = "24.05";
}
