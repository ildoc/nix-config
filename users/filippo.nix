{ config, pkgs, ... }:

{
  # ============================================================================
  # CONFIGURAZIONE HOME MANAGER - UTENTE FILIPPO
  # ============================================================================
  # Gestione dichiarativa dell'ambiente utente
  # Personalizzazioni specifiche per l'utente filippo
  
  # === CONFIGURAZIONE BASE ===
  home.username = "filippo";
  home.homeDirectory = "/home/filippo";
  
  # IMPORTANTE: Non modificare questa versione!
  # Assicura compatibilità delle migrazioni Home Manager
  home.stateVersion = "24.05";

  # === CONFIGURAZIONE GIT ===
  programs.git = {
    enable = true;
    
    # === IDENTITÀ SVILUPPATORE ===
    userName = "ildoc";
    userEmail = "il_doc@protonmail.com";
    
    # === CONFIGURAZIONI AVANZATE ===
    extraConfig = {
      # === IMPOSTAZIONI REPOSITORY ===
      init.defaultBranch = "main";        # Branch di default moderno
      pull.rebase = true;                 # Rebase invece di merge su pull
      push.autoSetupRemote = true;        # Setup automatico remote
      
      # === ALIAS PRODUTTIVITÀ ===
      alias = {
        # Alias brevi per comandi comuni
        st = "status";
        ci = "commit";
        br = "branch";
        co = "checkout";
        df = "diff";
        
        # Alias avanzati
        lg = "log --oneline --graph --decorate --all";  # Log grafico
        unstage = "reset HEAD --";                       # Rimuovi da staging
        last = "log -1 HEAD";                           # Ultimo commit
        visual = "!gitk";                               # GUI git
        
        # Workflow aliases
        sw = "switch";                                  # Switch branch (Git 2.23+)
        restore = "restore";                            # Restore files (Git 2.23+)
      };
    };
  };

  # === CONFIGURAZIONI ZSH PERSONALI ===
  programs.zsh = {
    enable = true;
    
    # === PERSONALIZZAZIONI SHELL ===
    initContent = ''
      # ========================================================================
      # CONFIGURAZIONI UTENTE SPECIFICHE
      # ========================================================================
      
      # === TEMA E ASPETTO ===
      # Mantieni tema robbyrussell per coerenza con sistema
      if [[ -n "$ZSH" ]]; then
        ZSH_THEME="robbyrussell"
      fi
      
      # === ALIAS DIRECTORY NAVIGATION ===
      # Scorciatoie per directory frequenti
      alias nixconf="cd ~/nix-config"
      alias projects="cd ~/Projects"
      alias downloads="cd ~/Downloads"
      alias docs="cd ~/Documents"
      
      # === ALIAS DEVELOPMENT ===
      # Git shortcuts (complementari a quelli in .gitconfig)
      alias gs="git status"
      alias ga="git add"
      alias gc="git commit"
      alias gp="git push"
      alias gl="git pull"
      alias gd="git diff"
      alias gb="git branch"
      alias gco="git checkout"
      alias gsw="git switch"
      
      # === DOCKER SHORTCUTS ===
      # Solo se Docker è disponibile
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
      
      # === KUBERNETES SHORTCUTS ===
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
      
      # === PERSONALIZZAZIONI HOST-SPECIFIC ===
      # Usa hostname invece di config per evitare dipendenze circolari
      CURRENT_HOST=$(hostname)
      case "$CURRENT_HOST" in
        "slimbook")
          # === LAPTOP DEVELOPMENT ===
          # Alias per applicazioni GUI
          alias code="code --disable-gpu-sandbox"  # VS Code con fix GPU
          alias rider="nohup rider > /dev/null 2>&1 &"
          
          # Gestione battery
          alias battery="upower -i /org/freedesktop/UPower/devices/battery_BAT0"
          ;;
          
        "gaming")
          # === GAMING WORKSTATION ===
          # Alias per applicazioni gaming
          alias discord="nohup discord > /dev/null 2>&1 &"
          alias steam="nohup steam > /dev/null 2>&1 &"
          alias lutris="nohup lutris > /dev/null 2>&1 &"
          
          # Performance monitoring
          alias temps="watch sensors"
          alias gpu="nvidia-smi"  # Se hai GPU NVIDIA
          ;;
          
        "dev-server")
          # === SERVER DEVELOPMENT ===
          # Server management
          alias logs="sudo journalctl -f"
          alias services="systemctl list-units --type=service"
          alias ports="ss -tulpn"
          ;;
      esac
      
      # === FUNZIONI DEVELOPMENT ===
      
      # Creazione progetto rapida
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
      
      # Docker cleanup completo
      docker-cleanup() {
        echo "Cleaning up Docker..."
        docker system prune -af --volumes
        echo "Docker cleanup completed!"
      }
      
      # Kubernetes context switch rapido
      kswitch() {
        if [ -z "$1" ]; then
          kubectl config get-contexts
        else
          kubectl config use-context "$1"
        fi
      }
      
      # === PRODUTTIVITÀ ===
      
      # Backup rapido file
      bak() {
        cp "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
        echo "Backup created: $1.bak.$(date +%Y%m%d_%H%M%S)"
      }
      
      # Cerca e sostituisci in directory
      replace() {
        if [ $# -ne 3 ]; then
          echo "Usage: replace <search> <replace> <directory>"
          return 1
        fi
        find "$3" -type f -exec grep -l "$1" {} \; | xargs sed -i "s/$1/$2/g"
      }
    '';
    
    # === VARIABILI D'AMBIENTE PERSONALI ===
    sessionVariables = {
      # Browser di default
      BROWSER = "firefox";
      
      # === DEVELOPMENT VARS ===
      # Node.js
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
      
      # === EDITOR PREFERENCES ===
      VISUAL = "code";
      EDITOR = "nano";
    };
  };

  # === PACCHETTI UTENTE PERSONALI ===
  home.packages = with pkgs; [
    # === UTILITY CLI ===
    bat                     # Cat colorato
    eza                     # ls moderno  
    fd                      # find moderno
    ripgrep                 # grep moderno
    tldr                    # man pages semplificate
    
    # === DEVELOPMENT TOOLS ===
    jq                      # JSON processor
    yq-go                   # YAML processor
    httpie                  # HTTP client user-friendly
    
    # === FILE MANAGEMENT ===
    unrar                   # Estrazione RAR
    p7zip                   # Supporto 7z
    
    # === GUI APPLICATIONS ===
    firefox                 # Browser
  ];

  # === CONFIGURAZIONI PROGRAMMI ===
  
  # === BAT (cat colorato) ===
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      paging = "never";
    };
  };
  
  # === EZA (ls moderno) ===
  programs.eza = {
    enable = true;
  };
  
  # === FZF (fuzzy finder) ===
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # === GESTIONE DOTFILES ===
  # Home Manager gestisce se stesso
  programs.home-manager.enable = true;
  
  # === CONFIGURAZIONI XDG ===
  # Standardizza directory utente
  xdg = {
    enable = true;
    
    userDirs = {
      enable = true;
      createDirectories = true;
      
      # Directory standard
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      videos = "$HOME/Videos";
      
      # Directory custom
      templates = "$HOME/Templates";
      publicShare = "$HOME/Public";
    };
  };
}
