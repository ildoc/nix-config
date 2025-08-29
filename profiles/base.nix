{ config, pkgs, lib, globalConfig, hostConfig, ... }:

let
  cfg = globalConfig;
in
{
  imports = [
    ../modules/core
  ];

  # ============================================================================
  # SYSTEM CONFIGURATION
  # ============================================================================
  system.stateVersion = cfg.system.stateVersion;
  
  # ============================================================================
  # NIX CONFIGURATION
  # ============================================================================
  nixpkgs.config.allowUnfree = true;
  
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0;
      
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      
      # Gestione spazio disco
      max-free = toString (5 * 1024 * 1024 * 1024);  # 5GB
      min-free = toString (1 * 1024 * 1024 * 1024);  # 1GB
    };
    
    # Garbage collection automatica
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
      persistent = true;
    };
    
    # Ottimizzazione store
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  # ============================================================================
  # LOCALE CONFIGURATION
  # ============================================================================
  time.timeZone = cfg.system.timezone;
  
  i18n = {
    defaultLocale = cfg.system.locale.default;
    extraLocaleSettings = cfg.system.locale.settings;
    supportedLocales = [
      "${cfg.system.locale.default}/UTF-8"
      "${cfg.system.locale.extra}/UTF-8"
    ];
  };
  
  console.useXkbConfig = true;

  # ============================================================================
  # SECURITY
  # ============================================================================
  security = {
    sudo.wheelNeedsPassword = false;
    rtkit.enable = true;
  };

  # ============================================================================
  # SSH CONFIGURATION
  # ============================================================================
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
      PermitRootLogin = "no";
      MaxAuthTries = 3;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
    };
  };

  # ============================================================================
  # FIREWALL
  # ============================================================================
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ cfg.ports.ssh ];
  };

  # ============================================================================
  # SHELL CONFIGURATION
  # ============================================================================
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ 
        "git" "sudo" "docker" "docker-compose"
        "kubectl" "history-substring-search"
        "colored-man-pages" "command-not-found"
      ];
    };
    
    interactiveShellInit = ''
      # History configuration
      HISTSIZE=10000
      SAVEHIST=10000
      setopt SHARE_HISTORY
      setopt HIST_VERIFY
      setopt EXTENDED_HISTORY
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_REDUCE_BLANKS
      
      # Basic aliases
      alias ll="ls -la"
      alias la="ls -A"
      alias l="ls -CF"
      alias ".."="cd .."
      alias "..."="cd ../.."
      alias grep="grep --color=auto"
      alias df="df -h"
      alias du="du -h"
      
      # NixOS management
      HOSTNAME=$(hostname)
      alias rebuild="sudo nixos-rebuild switch --flake /etc/nixos#$HOSTNAME"
      alias rebuild-test="sudo nixos-rebuild test --flake /etc/nixos#$HOSTNAME"
      alias rebuild-boot="sudo nixos-rebuild boot --flake /etc/nixos#$HOSTNAME"
      alias rebuild-dry="sudo nixos-rebuild dry-run --flake /etc/nixos#$HOSTNAME"
      alias flake-update="sudo nix flake update /etc/nixos"
      alias gc-full="sudo nix-collect-garbage -d && nix-store --gc"
      
      # Utility functions
      mkcd() { mkdir -p "$1" && cd "$1"; }
      backup() { cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"; }
      psg() { ps aux | grep -v grep | grep "$1"; }
      
      extract() {
        if [ -f "$1" ]; then
          case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.rar) unrar x "$1" ;;
            *.gz) gunzip "$1" ;;
            *.tar) tar xf "$1" ;;
            *.tbz2) tar xjf "$1" ;;
            *.tgz) tar xzf "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "'$1' cannot be extracted via extract()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }
      
      # User PATH
      if [[ "$USER" != "root" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
      fi
    '';
  };
  
  # Editor configuration
  programs.nano.enable = true;
  
  environment.variables = {
    EDITOR = "nano";
    VISUAL = "nano";
  };

  # ============================================================================
  # BASE PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs; 
    cfg.packages.system ++
    [
      # Version control
      git
      
      # Container tools
      kubectl
      
      # Hardware info
      pciutils
      usbutils
      
      # Security
      sops
      age
    ];

  # ============================================================================
  # USERS CONFIGURATION
  # ============================================================================
  users.users.root.shell = pkgs.zsh;

  # ============================================================================
  # COMMON ALIASES
  # ============================================================================
  environment.shellAliases = {
    # Git shortcuts
    g = "git";
    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git log --oneline --graph --decorate";
    
    # Docker shortcuts
    d = "docker";
    dc = "docker-compose";
    dps = "docker ps";
    
    # Kubernetes shortcuts  
    k = "kubectl";
    kgp = "kubectl get pods";
    kgs = "kubectl get services";
    
    # System info
    sysinfo = "fastfetch";
  };
}
