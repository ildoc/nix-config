{ config, pkgs, lib, hostname ? "", osConfig, ... }:

let
  isSlimbook = hostname == "slimbook";
  isDesktop = hostname == "slimbook" || hostname == "gaming";
  
  # Accedi all'email dal segreto se disponibile
  gitEmail = if (osConfig.sops.secrets ? "git/email") 
    then builtins.readFile osConfig.sops.secrets."git/email".path
    else "user@example.com";  # Placeholder generico, mai esposto
    
  gitConfig = osConfig.myConfig.users.filippo or {
    gitUserName = "ildoc";
    # gitUserEmail = gitEmail;
  };
in
{
  # IMPORTA LE CONFIGURAZIONI PLASMA PER I DESKTOP
  imports = lib.optionals isDesktop [ ./filippo-plasma.nix ];
  
  home.username = "filippo";
  home.homeDirectory = "/home/filippo";
  
  # IMPORTANTE: Non modificare
  home.stateVersion = "25.05";

  # ============================================================================
  # GIT CONFIGURATION
  # ============================================================================
  programs.git = {
    enable = true;
    userName = gitConfig.gitUserName;
    # NON impostiamo userEmail - verrà configurata dopo il primo boot
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      
      # SSH signing (opzionale, se vuoi firmare i commit)
      commit.gpgsign = false;  # Metti true se vuoi abilitarlo
      # user.signingkey = "~/.ssh/id_ed25519.pub";
      # gpg.format = "ssh";
      
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

  # ============================================================================
  # SHELL ENHANCEMENTS
  # ============================================================================
  programs.zsh = {
    enable = true;
    
    # Abilita integrazioni
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    initContent = ''
      # Theme sarà gestito da starship
      
      # Directory shortcuts
      alias nixconf="cd /etc/nixos"
      alias projects="cd ~/Projects"
      alias downloads="cd ~/Downloads"
      alias docs="cd ~/Documents"
      
      # Alias per i nuovi tools
      alias ls="eza --icons"
      alias ll="eza -la --icons"
      alias la="eza -a --icons"
      alias lt="eza --tree --icons"
      alias cat="bat"
      
      # Kubernetes shortcuts
      if command -v kubectl >/dev/null 2>&1; then
        alias k="kubectl"
      fi
      
      # Host-specific
      ${if isSlimbook then ''
        alias code="code --disable-gpu-sandbox"
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
      
      # Quick cd con zoxide
      eval "$(zoxide init zsh)"
    '';
    
    sessionVariables = {
      BROWSER = "firefox";
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
      VISUAL = "code --wait";
      EDITOR = "code --wait";
      SOPS_EDITOR = "code --wait";  # Editor specifico per SOPS
      SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";  # Path della chiave Age
    };
  };

  # ============================================================================
  # STARSHIP PROMPT
  # ============================================================================
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    
    settings = {
      format = ''
        [┌───────────────────>](bold blue)
        [│](bold blue) $username$hostname$directory$git_branch$git_status$nix_shell$nodejs$python$dotnet$docker_context
        [└─>](bold blue) $character
      '';
      
      username = {
        show_always = false;
        style_user = "blue bold";
        style_root = "red bold";
        format = "[$user]($style) ";
      };
      
      hostname = {
        ssh_only = false;
        format = "@ [$hostname](bold purple) ";
        disabled = false;
      };
      
      directory = {
        style = "cyan bold";
        truncation_length = 3;
        truncate_to_repo = false;
        format = "in [$path]($style) ";
      };
      
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
        vicmd_symbol = "[⮜](bold yellow)";
      };
      
      git_branch = {
        symbol = " ";
        style = "yellow bold";
        format = "on [$symbol$branch]($style) ";
      };
      
      git_status = {
        format = "([\\[$all_status$ahead_behind\\]]($style) )";
        conflicted = "⚔️ ";
        ahead = "⬆️ ×\${count}";
        behind = "⬇️ ×\${count}";
        diverged = "🔀 ";
        untracked = "🤷×\${count}";
        stashed = "📦 ";
        modified = "📝×\${count}";
        staged = "🗃️ ×\${count}";
        renamed = "📛×\${count}";
        deleted = "🗑️ ×\${count}";
        style = "red bold";
      };
      
      nodejs = {
        format = "via [⬢ $version](bold green) ";
        detect_extensions = ["js" "mjs" "cjs" "ts" "mts" "cts"];
      };
      
      python = {
        format = "via [🐍 $version](bold yellow) ";
      };
      
      dotnet = {
        format = "via [🎯 $version](bold purple) ";
        detect_extensions = ["csproj" "fsproj" "xproj"];
      };
      
      docker_context = {
        format = "via [🐳 $context](blue bold) ";
        only_with_files = false;
      };
      
      nix_shell = {
        format = "via [❄️ $state( \\($name\\))](bold blue) ";
        impure_msg = "[impure](bold red)";
        pure_msg = "[pure](bold green)";
      };
      
      # Battery for laptop
      battery = lib.mkIf (hostname == "slimbook") {
        full_symbol = "🔋";
        charging_symbol = "⚡";
        discharging_symbol = "💀";
        display = [
          { threshold = 10; style = "bold red"; }
          { threshold = 30; style = "bold yellow"; }
          { threshold = 100; style = "bold green"; }
        ];
      };
      
      time = {
        disabled = false;
        format = "🕙[\\[ $time \\]]($style) ";
        time_format = "%T";
        style = "bold yellow";
      };
    };
  };

  # ============================================================================
  # ADVANCED SHELL TOOLS
  # ============================================================================
  
  # BAT - Better cat
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      paging = "never";
      style = "numbers,changes,header";
    };
    extraPackages = with pkgs.bat-extras; [
      batdiff
      batman
      batgrep
      batwatch
    ];
  };
  
  # EZA - Better ls
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
  
  # ZOXIDE - Smarter cd
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd"  # Sostituisce cd con zoxide
    ];
  };
  
  # FZF - Fuzzy finder
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
      "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
    ];
  };

  # ============================================================================
  # PACKAGES
  # ============================================================================
  home.packages = with pkgs; [
    # Shell enhancements già configurati sopra
    fd
    ripgrep
    tldr
    jq
    yq-go
    httpie
    
    # Archives
    unrar
    p7zip
    
    # Browser
    firefox
    
    # Dev tools
    lazygit
    
    # System tools
    btop      # Better htop
    duf       # Better df
    dust      # Better du
    procs     # Better ps
  ];

  # ============================================================================
  # HOME MANAGER
  # ============================================================================
  programs.home-manager.enable = true;
  
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
  
  # Create custom directories
  systemd.user.tmpfiles.rules = [
    "d ${config.home.homeDirectory}/Projects 0755 ${config.home.username} users -"
    "d ${config.home.homeDirectory}/Pictures/Screenshots 0755 ${config.home.username} users -"
  ];
}
