{ config, pkgs, ... }:

{
  programs.nano.enable = true;
  
  environment.variables = {
    EDITOR = "nano";
    VISUAL = "nano";
  };

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
      
      # Kubernetes
      if command -v kubectl >/dev/null 2>&1; then
        alias k="kubectl"
      fi
      
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
      
      # Host-specific configuration
      case "$HOSTNAME" in
        "slimbook")
          export KUBE_EDITOR="nano"
          export EDITOR="nano"
          export VISUAL="nano"
          if [[ "$USER" != "root" ]]; then
            alias rider="nohup rider > /dev/null 2>&1 &"
          fi
          ;;
      esac
      
      # User PATH
      if [[ "$USER" != "root" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        DEFAULT_USER="filippo"
      fi
    '';
  };
}
