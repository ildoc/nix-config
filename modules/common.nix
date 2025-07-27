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

  nixpkgs.config.allowUnfree = true;

  # ZSH configuration (sistema - configurazione base per tutti gli utenti)
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ 
        "git"
        "sudo"
        "docker"
        "docker-compose"
        "kubectl"
        "history-substring-search"
        "colored-man-pages"
        "command-not-found"
      ];
    };
    
    # Configurazioni shell comuni
    interactiveShellInit = ''
      # History settings
      HISTSIZE=10000
      SAVEHIST=10000
      setopt SHARE_HISTORY
      setopt HIST_VERIFY
      setopt EXTENDED_HISTORY
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_REDUCE_BLANKS
      
      # Common aliases
      alias ll="ls -la"
      alias la="ls -A"
      alias l="ls -CF"
      alias ".."="cd .."
      alias "..."="cd ../.."
      alias grep="grep --color=auto"
      alias df="df -h"
      alias du="du -h"
            
      # NixOS specific
      alias rebuild="sudo nixos-rebuild switch --flake"
      alias rebuild-test="sudo nixos-rebuild test --flake"
      alias rebuild-boot="sudo nixos-rebuild boot --flake"
      alias rebuild-dry="sudo nixos-rebuild dry-run --flake"
      alias flake-update="sudo nix flake update"
      alias gc-full="sudo nix-collect-garbage -d && nix-store --gc"
      
      # Kubernetes shortcuts (se disponibile)
      if command -v kubectl >/dev/null 2>&1; then
        alias k="kubectl"
      fi
      
      # Common functions
      mkcd() { mkdir -p "$1" && cd "$1"; }
      backup() { cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"; }
      psg() { ps aux | grep -v grep | grep "$1"; }
      
      # Extract function
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
      
      # Host-specific configurations
      case "$(hostname)" in
        "dev-server")
          export DOCKER_HOST="unix:///var/run/docker.sock"
          export KUBE_EDITOR="nano"
          export EDITOR="nano"
          export VISUAL="nano"
          ;;
        "slimbook")
          export KUBE_EDITOR="nano"
          export EDITOR="nano"
          export VISUAL="nano"
          if [[ "$USER" != "root" ]]; then
            alias rider="nohup rider > /dev/null 2>&1 &"
          fi
          ;;
        "gaming")
          export EDITOR="nano"
          export VISUAL="nano"
          if [[ "$USER" != "root" ]]; then
            alias steam="nohup steam > /dev/null 2>&1 &"
          fi
          ;;
      esac
      
      # Add ~/.local/bin to PATH (solo per utenti non root)
      if [[ "$USER" != "root" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
      fi
      
      # Prompt customization
      if [[ "$USER" != "root" ]]; then
        DEFAULT_USER="filippo"
      fi
    '';
  };

  # Editor di default
  programs.nano.enable = true;
  environment.variables = {
    EDITOR = "nano";
    VISUAL = "nano";
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # Pacchetti di base comuni
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    htop
    tree
    unzip
    zip
    nmap
    tcpdump
    lsof
    strace
    file
    which
    fastfetch
    
    # Kubernetes tools (disponibili su tutti gli host)
    kubectl
  ];

  # Configurazione utente filippo
  users.users.filippo = {
    isNormalUser = true;
    description = "Filippo";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  # Configurazione utente root con ZSH
  users.users.root = {
    shell = pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "24.05";
}
