{ config, pkgs, ... }:

{
  # Configurazione Home Manager per utente filippo
  
  home.username = "filippo";
  home.homeDirectory = "/home/filippo";
  home.stateVersion = "24.05";

  # Configurazione ZSH
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    
    # Alias personalizzati
    shellAliases = {
      # Navigazione
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";
      
      # Utilities
      grep = "grep --color=auto";
      df = "df -h";
      du = "du -h";
      
      # NixOS specific
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos";
      update = "sudo nix flake update /etc/nixos";

    };
    
    # Variabili d'ambiente
    sessionVariables = {
      EDITOR = "nano";
      BROWSER = "firefox";
      TERMINAL = "alacritty";
    };
    
    # Configurazione oh-my-zsh
    oh-my-zsh = {
      enable = true;
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
      theme = "agnoster";
    };
    
    # Configurazioni aggiuntive per .zshrc
    initExtra = ''
      # Configurazioni personalizzate
      
      # History settings
      HISTSIZE=10000
      SAVEHIST=10000
      setopt SHARE_HISTORY
      setopt HIST_VERIFY
      setopt EXTENDED_HISTORY
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_REDUCE_BLANKS
      
      # Funzioni personalizzate
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }
      
      # Backup function
      backup() {
        cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"
      }
      
      # Find process by name
      psg() {
        ps aux | grep -v grep | grep "$1"
      }
      
      # Extract archives
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
      
      # Kubernetes shortcuts
      alias k="kubectl"
      
      # Prompt customization per agnoster
      DEFAULT_USER="filippo"
      
      # Aggiungi ~/.local/bin al PATH
      export PATH="$HOME/.local/bin:$PATH"
      
      # Configurazioni specifiche per host
      case "$(hostname)" in
        "dev-server")
          # Configurazioni specifiche per server
          export DOCKER_HOST="unix:///var/run/docker.sock"
          ;;
        "laptop")
          # Configurazioni specifiche per laptop
          alias rider="nohup rider > /dev/null 2>&1 &"
          ;;
        "gaming")
          # Configurazioni specifiche per desktop
          alias steam="nohup steam > /dev/null 2>&1 &"
          ;;
      esac
    '';
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "ildoc";
    userEmail = "il_doc@protonmail.com";
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;      
    };
  };

  # Alacritty terminal (se disponibile)
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.9;
        padding = {
          x = 10;
          y = 10;
        };
      };
      
      font = {
        normal = {
          family = "Fira Code";
          style = "Regular";
        };
        size = 12;
      };
      
      colors = {
        primary = {
          background = "#1e1e1e";
          foreground = "#d4d4d4";
        };
      };
    };
  };

  # Home Manager deve gestire se stesso
  programs.home-manager.enable = true;
}
