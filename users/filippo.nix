{ config, pkgs, lib, hostname ? "", ... }:

let
  isSlimbook = hostname == "slimbook";
in
{
  home.username = "filippo";
  home.homeDirectory = "/home/filippo";
  
  # IMPORTANTE: Non modificare
  home.stateVersion = "24.05";

  programs.git = {
    enable = true;
    userName = "ildoc";
    userEmail = "il_doc@protonmail.com";
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      
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
        sw = "switch";
        restore = "restore";
      };
    };
  };

  programs.zsh = {
    enable = true;
    
    initContent = ''
      # Theme
      if [[ -n "$ZSH" ]]; then
        ZSH_THEME="robbyrussell"
      fi
      
      # Directory shortcuts
      alias nixconf="cd ~/nix-config"
      alias projects="cd ~/Projects"
      alias downloads="cd ~/Downloads"
      alias docs="cd ~/Documents"
      
      # Git shortcuts
      alias gs="git status"
      alias ga="git add"
      alias gc="git commit"
      alias gp="git push"
      alias gl="git pull"
      alias gd="git diff"
      alias gb="git branch"
      alias gco="git checkout"
      alias gsw="git switch"
      
      # Docker shortcuts
      if command -v docker >/dev/null 2>&1; then
        alias dps="docker ps"
        alias dpsa="docker ps -a"
        alias di="docker images"
        alias drmi="docker rmi"
        alias drm="docker rm"
        alias dlog="docker logs"
        alias dexec="docker exec -it"
        alias dstop="docker stop"
        alias dstart="docker start"
        alias dclean="docker system prune -f"
      fi
      
      # Kubernetes shortcuts
      if command -v kubectl >/dev/null 2>&1; then
        alias k="kubectl"
        alias kgp="kubectl get pods"
        alias kgs="kubectl get services"
        alias kgd="kubectl get deployments"
        alias kdp="kubectl describe pod"
        alias kds="kubectl describe service"
        alias kdd="kubectl describe deployment"
        alias klog="kubectl logs"
        alias kexec="kubectl exec -it"
        alias kctx="kubectl config current-context"
        alias kns="kubectl config set-context --current --namespace"
      fi
      
      # Host-specific
      ${if isSlimbook then ''
        alias code="code --disable-gpu-sandbox"
        alias rider="nohup rider > /dev/null 2>&1 &"
        alias battery="upower -i /org/freedesktop/UPower/devices/battery_BAT0"
      '' else ""}
      
      # Functions
      newproject() {
        if [ -z "$1" ]; then
          echo "Usage: newproject <project-name>"
          return 1
        fi
        mkdir -p ~/Projects/"$1"
        cd ~/Projects/"$1"
        git init
        echo "# $1" > README.md
        echo "Created new project: $1"
      }
      
      docker-cleanup() {
        echo "Cleaning up Docker..."
        docker system prune -af --volumes
        echo "Docker cleanup completed!"
      }
      
      kswitch() {
        if [ -z "$1" ]; then
          kubectl config get-contexts
        else
          kubectl config use-context "$1"
        fi
      }
      
      bak() {
        cp "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
        echo "Backup created: $1.bak.$(date +%Y%m%d_%H%M%S)"
      }
      
      replace() {
        if [ $# -ne 3 ]; then
          echo "Usage: replace <search> <replace> <directory>"
          return 1
        fi
        find "$3" -type f -exec grep -l "$1" {} \; | xargs sed -i "s/$1/$2/g"
      }
    '';
    
    sessionVariables = {
      BROWSER = "firefox";
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
      VISUAL = "code";
      EDITOR = "nano";
    };
  };

  home.packages = with pkgs; [
    bat
    eza
    fd
    ripgrep
    tldr
    jq
    yq-go
    httpie
    unrar
    p7zip
    firefox
  ];

  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      paging = "never";
    };
  };
  
  programs.eza = {
    enable = true;
  };
  
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.home-manager.enable = true;
  
  xdg = {
    enable = true;
    
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      videos = "$HOME/Videos";
      templates = "$HOME/Templates";
      publicShare = "$HOME/Public";
    };
  };
  
}
