{ config, pkgs, ... }:

{
  # Configurazione Home Manager per utente filippo
  
  home.username = "filippo";
  home.homeDirectory = "/home/filippo";
  home.stateVersion = "24.05";

  # Git configuration (personale - rimossa da common.nix)
  programs.git = {
    enable = true;
    userName = "ildoc";
    userEmail = "il_doc@protonmail.com";
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      
      # Alias utili
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

  # Configurazioni ZSH personali (aggiuntive a quelle di sistema)
  programs.zsh = {
    enable = true;
    
    # Configurazioni aggiuntive personali
    initExtra = ''
      # Personalizzazioni utente specifiche
      
      # Tema agnoster per l'utente (sistema usa robbyrussell)
      if [[ -n "$ZSH" ]]; then
        ZSH_THEME="robbyrussell"
      fi
      
      # Funzioni personali aggiuntive
      # Quick cd to common directories
      alias nixconf="cd ~/nixos-config"
      alias projects="cd ~/Projects"
      alias downloads="cd ~/Downloads"
      
      # Development shortcuts
      # alias gs="git status"
      # alias ga="git add"
      # alias gc="git commit"
      # alias gp="git push"
      # alias gl="git pull"
      # alias gd="git diff"
      # alias gb="git branch"
      
      # Docker shortcuts (se disponibile)
      # if command -v docker >/dev/null 2>&1; then
      #   alias dps="docker ps"
      #   alias dpsa="docker ps -a"
      #   alias di="docker images"
      #   alias drmi="docker rmi"
      #   alias drm="docker rm"
      #   alias dlog="docker logs"
      #   alias dexec="docker exec -it"
      # fi
      
      # Kubernetes shortcuts personali
      if command -v kubectl >/dev/null 2>&1; then
        alias k="kubectl"
        # alias kgp="kubectl get pods"
        # alias kgs="kubectl get services"
        # alias kgd="kubectl get deployments"
        # alias kdp="kubectl describe pod"
        # alias kds="kubectl describe service"
        # alias kdd="kubectl describe deployment"
        # alias klog="kubectl logs"
        # alias kexec="kubectl exec -it"
      fi
      
      # Host-specific personalizations
      case "$(hostname)" in
        "laptop")
          # Laptop-specific user aliases
          alias code="code-oss"
          ;;
        "gaming")
          # Gaming-specific user aliases
          alias discord="nohup discord > /dev/null 2>&1 &"
          ;;
      esac
    '';
    
    # Variabili d'ambiente personali
    sessionVariables = {
      BROWSER = "firefox";
      # Rimuoviamo TERMINAL perché usiamo Konsole di KDE
    };
  };

  # Home packages personali (non di sistema)
  home.packages = with pkgs; [
    # Utility personali
    ripgrep
    fd
    bat
    exa
    
    # Development tools personali
    jq
    yq
    
    # Only if not on server
  ] ++ (if config.home.username != "root" then [
    # GUI applications only for non-root user
  ] else []);

  # Home Manager deve gestire se stesso
  programs.home-manager.enable = true;
}
