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

  nixpkgs.config.allowUnfree = true;

  # ZSH configuration (comune a tutti gli host)
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    
    ohMyZsh = {
      enable = true;
      theme = "agnoster";
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
    
    # Configurazioni shell comuni (equivalente a .zshrc condiviso)
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
      
      # Prompt customization per agnoster
      DEFAULT_USER="filippo"
      
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
      alias rebuild="sudo nixos-rebuild switch --flake /etc/nixos"
      alias update="sudo nix flake update /etc/nixos"
      
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
          alias k="kubectl"
          ;;
        "work-laptop")
          alias rider="nohup rider > /dev/null 2>&1 &"
          ;;
        "gaming-rig")
          alias steam="nohup steam > /dev/null 2>&1 &"
          ;;
      esac
      
      # Add ~/.local/bin to PATH
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };

  # Git global configuration
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      user = {
        name = "ildoc";
        email = "il_doc@protonmail.com";
      };
      alias = {
        st = "status";
        ci = "commit";
        br = "branch";
        co = "checkout";
        df = "diff";
        lg = "log --oneline --graph --decorate --all";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        visual = "!gitk";
      };
    };
  };

  programs.vim.defaultEditor = true;

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

  # Pacchetti di base
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
    tree
  ];

  # Configurazione utente filippo
  users.users.filippo = {
    isNormalUser = true;
    description = "Filippo";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "24.05";
}
