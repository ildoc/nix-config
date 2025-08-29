{ config, pkgs, lib, inputs, hostname, hostConfig, ... }:

let
  cfg = globalConfig;
  userCfg = cfg.users.filippo;
  isDesktop = hostConfig.features.desktop or false;
in
{
  # Import Plasma configuration if desktop
  imports = lib.optionals isDesktop [ 
    ../modules/plasma.nix 
  ];

  home.username = userCfg.username;
  home.homeDirectory = "/home/${userCfg.username}";
  home.stateVersion = cfg.system.stateVersion;

  # ============================================================================
  # GIT CONFIGURATION
  # ============================================================================
  programs.git = {
    enable = true;
    userName = userCfg.gitUserName;
    # userEmail viene configurato da SOPS dopo il primo boot
    
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
        sw = "switch";
      };
    };
    
    includes = [
      {
        path = "~/.gitconfig.local";
        condition = null;
      }
    ];
  };

  # ============================================================================
  # ZSH CONFIGURATION
  # ============================================================================
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    initExtra = ''
      # Directory shortcuts
      alias nixconf="cd ${cfg.paths.nixosConfig}"
      alias projects="cd ~/Projects"
      
      # Enhanced ls/cat with new tools
      alias ls="eza --icons"
      alias ll="eza -la --icons"
      alias la="eza -a --icons"
      alias lt="eza --tree --icons"
      alias cat="bat"
      
      # Docker shortcuts
      docker-cleanup() {
        echo "Cleaning up Docker..."
        docker system prune -af --volumes
      }
      
      # Kubernetes context switcher
      kswitch() {
        if [ -z "$1" ]; then
          kubectl config get-contexts
        else
          kubectl config use-context "$1"
        fi
      }
      
      # Project creator
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
      
      # Zoxide initialization
      eval "$(zoxide init zsh)"
      
      ${lib.optionalString (hostname == "slimbook") ''
        alias code="code --disable-gpu-sandbox"
        alias battery="upower -i /org/freedesktop/UPower/devices/battery_BAT0"
      ''}
    '';
    
    sessionVariables = {
      BROWSER = "firefox";
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
      EDITOR = if isDesktop then "code --wait" else "nano";
      VISUAL = if isDesktop then "code --wait" else "nano";
      SOPS_EDITOR = if isDesktop then "code --wait" else "nano";
      SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
    };
  };

  # ============================================================================
  # STARSHIP PROMPT
  # ============================================================================
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    
    settings = {
      format = "$directory$git_branch$git_status $character";
      right_format = "$time";
      
      directory = {
        style = "cyan";
        truncation_length = 3;
        format = "[$path]($style) ";
      };
      
      git_branch = {
        symbol = " ";
        style = "yellow";
        format = "on [$symbol$branch]($style) ";
      };
      
      git_status = {
        format = "[$all_status]($style) ";
        style = "red";
      };
      
      character = {
        success_symbol = "[➜](bold green) ";
        error_symbol = "[➜](bold red) ";
      };
      
      time = {
        disabled = false;
        format = "[$time]($style)";
        time_format = "%H:%M:%S";
        style = "bold yellow";
      };
      
      # Disable unnecessary modules
      username.disabled = true;
      hostname.disabled = true;
      nodejs.disabled = true;
      python.disabled = true;
      dotnet.disabled = true;
      docker_context.disabled = true;
      nix_shell.disabled = true;
      battery.disabled = true;
    };
  };

  # ============================================================================
  # ADVANCED SHELL TOOLS
  # ============================================================================
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      paging = "never";
      style = "numbers,changes,header";
    };
  };
  
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };
  
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };
  
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
    ];
  };

  # ============================================================================
  # USER PACKAGES
  # ============================================================================
  home.packages = with pkgs; 
    cfg.packages.shell ++ [
      # Development tools
      lazygit
      
      # System monitoring
      btop
      duf
      dust
      procs
    ] ++ lib.optionals isDesktop (
      hostConfig.applications.additional or []
    );

  # ============================================================================
  # XDG DIRECTORIES
  # ============================================================================
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
  
  # Custom directories
  systemd.user.tmpfiles.rules = [
    "d ${config.home.homeDirectory}/Projects 0755 ${userCfg.username} users -"
    "d ${config.home.homeDirectory}/Pictures/Screenshots 0755 ${userCfg.username} users -"
  ];
  
  # Home Manager
  programs.home-manager.enable = true;
}
