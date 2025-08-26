{ config, pkgs, lib, hostname ? "", ... }:

let
  isDesktop = hostname == "slimbook" || hostname == "gaming";
  
  # Percorsi dei wallpaper - assicurati che esistano in /etc/nixos/assets/wallpapers/
  wallpapers = {
    slimbook = ../../assets/wallpapers/slimbook.jpg;
    gaming = ../../assets/wallpapers/gaming.jpg;
  };
  
  # Wallpaper di default se non esiste quello specifico
  currentWallpaper = wallpapers.${hostname} or ../../assets/wallpapers/default.jpg;
in
{
  # Solo per sistemi con desktop KDE
  config = lib.mkIf isDesktop {
    programs.plasma = {
      enable = true;
      
      # ============================================================================
      # WORKSPACE - Configurazioni generali del desktop
      # ============================================================================
      workspace = {
        # Tema e aspetto
        lookAndFeel = "org.kde.breezedark.desktop";
        theme = "breeze-dark";
        colorScheme = "BreezeDark";
        iconTheme = "breeze-dark";
        
        # Wallpaper
        wallpaper = currentWallpaper;
        
        # Cursore
        cursor = {
          theme = "breeze_cursors";
          size = 24;
        };
        
        # Click policy
        clickItemTo = "select";  # o "open" per single-click
      };
      
      # ============================================================================
      # PANELS - Configurazione pannelli e taskbar
      # ============================================================================
      panels = [
        {
          # Pannello principale in basso
          location = "bottom";
          height = 44;
          floating = false;
          
          widgets = [
            # Application launcher
            {
              name = "org.kde.plasma.kickoff";
              config = {
                General.icon = "nix-snowflake-white";
                General.favoritesDisplay = 0;  # 0 = list, 1 = grid
              };
            }
            
            # Task Manager con applicazioni pinnate
            {
              name = "org.kde.plasma.icontasks";
              config = {
                General = {
                  launchers = if (hostname == "slimbook") then [
                    # Applicazioni pinnate per Slimbook nell'ordine specifico
                    "applications:systemsettings.desktop"      # System Settings
                    "applications:org.kde.dolphin.desktop"     # Dolphin
                    "applications:jetbrains-rider.desktop"     # Rider
                    "applications:org.kde.konsole.desktop"     # Konsole
                    "applications:firefox.desktop"             # Firefox
                    "applications:org.telegram.desktop.desktop" # Telegram (nome corretto)
                    "applications:code.desktop"                # VS Code
                    "applications:teams-for-linux.desktop"     # Teams
                    "applications:spotify.desktop"             # Spotify
                  ] else if (hostname == "gaming") then [
                    # Applicazioni pinnate per Gaming
                    "applications:org.kde.dolphin.desktop"     # Dolphin
                    "applications:firefox.desktop"             # Firefox
                    "applications:org.kde.konsole.desktop"     # Konsole
                    "applications:steam.desktop"               # Steam
                    "applications:discord.desktop"             # Discord
                    "applications:lutris.desktop"              # Lutris
                    "applications:heroic.desktop"              # Heroic
                    "applications:spotify.desktop"             # Spotify
                  ] else [
                    # Default per altri host
                    "applications:org.kde.dolphin.desktop"
                    "applications:firefox.desktop"
                    "applications:org.kde.konsole.desktop"
                  ];
                  
                  showOnlyCurrentDesktop = false;
                  showOnlyCurrentActivity = true;
                  groupingStrategy = 1;  # 0=Don't group, 1=By program
                  maxStripes = 1;
                };
              };
            }
            
            # Spacer
            "org.kde.plasma.marginsseparator"
            
            # System tray
            {
              name = "org.kde.plasma.systemtray";
              config = {
                General.spacing = 4;
                General.scaleIconsToFit = true;
              };
            }
            
            # Clock
            {
              name = "org.kde.plasma.digitalclock";
              config = {
                Appearance = {
                  dateFormat = "isoDate";
                  use24hFormat = 2;  # 0=12h, 1=Use Region Defaults, 2=24h
                  showSeconds = false;
                  showDate = true;
                  dateDisplayFormat = 0; # 0=Adaptive, 1=Always Beside Time, 2=Always Below Time
                };
              };
            }
            
            # Show desktop button
            "org.kde.plasma.showdesktop"
          ];
        }
      ];
      
      # ============================================================================
      # SHORTCUTS - Scorciatoie da tastiera personalizzate
      # ============================================================================
      shortcuts = {
        "kwin" = {
          "Switch to Desktop 1" = "Meta+1";
          "Switch to Desktop 2" = "Meta+2";
          "Switch to Desktop 3" = "Meta+3";
          "Switch to Desktop 4" = "Meta+4";
          "Maximize Window" = "Meta+Up";
          "Minimize Window" = "Meta+Down";
          "Close Window" = "Alt+F4";
          "Show Desktop" = "Meta+D";
          "Window to Desktop 1" = "Meta+Shift+1";
          "Window to Desktop 2" = "Meta+Shift+2";
          "Window to Desktop 3" = "Meta+Shift+3";
          "Window to Desktop 4" = "Meta+Shift+4";
          "Overview" = "Meta+W";
        };
        
        # Shortcuts personalizzate per applicazioni
        "services/org.kde.konsole.desktop" = {
          "_launch" = "Ctrl+Alt+T";
        };
        
        "services/firefox.desktop" = {
          "_launch" = "Meta+B";
        };
        
        "services/org.kde.dolphin.desktop" = {
          "_launch" = "Meta+E";
        };
        
        "services/org.kde.spectacle.desktop" = {
          "RectangularRegionScreenShot" = "Print";
          "CurrentMonitorScreenShot" = "Meta+Print";
          "FullScreenScreenShot" = "Shift+Print";
        };
      };
      
      # ============================================================================
      # KWIN - Window Manager configurations
      # ============================================================================
      kwin = {
        effects = {
          blur.enable = true;
          desktopGrid.enable = true;
          dimInactive.enable = false;
          presentWindows.enable = true;
          slide.enable = true;
          translucency.enable = true;
          wobblyWindows.enable = false;
        };
        
        # Numero di desktop virtuali
        virtualDesktops = {
          rows = 1;
          number = 4;
          names = [ "Main" "Dev" "Communication" "Extra" ];
        };
        
        # Comportamento finestre
        titlebarButtons = {
          left = [ "on-all-desktops" "keep-above-windows" ];
          right = [ "minimize" "maximize" "close" ];
        };
        
        # Focus delle finestre
        focusPolicy = "click";  # o "focusFollowsMouse"
        
        # Bordi dello schermo
        borderlessMaximizedWindows = true;
        
        # Night Color (filtro luce blu)
        nightLight = {
          enable = true;
          mode = "location";  # o "times" per orari fissi
          location = {
            latitude = 44.4056;  # Genova
            longitude = 8.9463;
          };
          temperature = {
            day = 6500;
            night = 4500;
          };
        };
      };
      
      # ============================================================================
      # POWER MANAGEMENT - Gestione energetica
      # ============================================================================
      powerdevil = {
        AC = {
          # Quando collegato alla corrente
          autoSuspend = {
            action = "nothing";
            idleTimeout = "never";
          };
          
          turnOffDisplay = {
            idleTimeout = 1800;  # 30 minuti in secondi
            idleTimeoutWhenLocked = 300;  # 5 minuti quando bloccato
          };
          
          dimDisplay = {
            enable = true;
            idleTimeout = 600;  # 10 minuti in secondi
          };
          
          # Performance profile
          powerProfile = "performance";
          
          # Gestione coperchio laptop (solo slimbook)
          whenLaptopLidClosed = if (hostname == "slimbook") then "doNothing" else "turnOffScreen";
        };
        
        battery = lib.mkIf (hostname == "slimbook") {
          # Su batteria (solo per laptop)
          autoSuspend = {
            action = "sleep";
            idleTimeout = 1800;  # 30 minuti
          };
          
          turnOffDisplay = {
            idleTimeout = 600;  # 10 minuti
            idleTimeoutWhenLocked = 60;  # 1 minuto quando bloccato
          };
          
          dimDisplay = {
            enable = true;
            idleTimeout = 300;  # 5 minuti
          };
          
          powerProfile = "balanced";
          
          whenLaptopLidClosed = "sleep";
        };
        
        lowBattery = lib.mkIf (hostname == "slimbook") {
          # Batteria scarica (solo per laptop)
          autoSuspend = {
            action = "hibernate";
            idleTimeout = 300;  # 5 minuti
          };
          
          turnOffDisplay = {
            idleTimeout = 120;  # 2 minuti
          };
          
          powerProfile = "powerSave";
        };
      };
      
      # ============================================================================
      # CONFIGURAZIONI REGIONALI E FILE CONFIG
      # ============================================================================
      configFile = {
        # Configurazioni regionali italiane
        "plasma-localerc" = {
          "Formats" = {
            "LANG" = "it_IT.UTF-8";
            "LC_ADDRESS" = "it_IT.UTF-8";
            "LC_MEASUREMENT" = "it_IT.UTF-8";
            "LC_MONETARY" = "it_IT.UTF-8";
            "LC_NAME" = "it_IT.UTF-8";
            "LC_NUMERIC" = "it_IT.UTF-8";
            "LC_PAPER" = "it_IT.UTF-8";
            "LC_TELEPHONE" = "it_IT.UTF-8";
            "LC_TIME" = "it_IT.UTF-8";
            "useDetailed" = true;
          };
        };
        
        # Screen lock settings
        "kscreenlockerrc" = {
          "Daemon" = {
            "Autolock" = true;
            "LockOnResume" = true;
            "Timeout" = 10;  # Minuti prima del lock automatico
          };
          
          "Greeter" = {
            "Theme" = "org.kde.breezedark.desktop";
          };
        };
        
        # Notifiche
        "plasmanotifyrc" = {
          "Notifications" = {
            "PopupPosition" = "BottomRight";
            "PopupTimeout" = 5000;
          };
        };
        
        # File manager (Dolphin) settings
        "dolphinrc" = {
          "General" = {
            "ShowFullPath" = true;
            "ShowStatusBar" = true;
            "ShowToolTips" = true;
            "RememberOpenedTabs" = false;
          };
          
          "PreviewSettings" = {
            "Plugins" = "directorythumbnail,imagethumbnail,jpegthumbnail,svgthumbnail,ffmpegthumbs";
          };
        };
        
        # Konsole settings
        "konsolerc" = {
          "Desktop Entry" = {
            "DefaultProfile" = "Profile 1.profile";
          };
          
          "MainWindow" = {
            "MenuBar" = "Disabled";
            "ToolBarsMovable" = "Disabled";
          };
        };
        
        # KDE Connect (solo per slimbook)
        "kdeconnect" = lib.mkIf (hostname == "slimbook") {
          "General" = {
            "name" = "NixOS Slimbook";
          };
        };
        
        # Spectacle (screenshot tool) settings
        "spectaclerc" = {
          "General" = {
            "autoSaveImage" = true;
            "clipboardGroup" = "PostScreenshotCopyImage";
            "compressionQuality" = 90;
            "defaultSaveLocation" = "file:///home/USERNAME/Pictures/Screenshots";
            "filename" = "Screenshot_%Y%M%d_%H%m%S";
            "imageFormat" = "PNG";
            "launchAction" = "UseLastUsedCapturemode";
            "onLaunchAction" = "DoNotTakeScreenshot";
            "quitAfterSaveCopyExport" = false;
            "rememberLastRectangularSelection" = true;
            "showMagnifierChecked" = true;
            "useReleaseToCapture" = true;
          };
          "GuiConfig" = {
            "captureDelay" = 0;
            "captureModeIndex" = 1; # 1 = rectangular region
            "captureOnClick" = false;
            "quitAfterSaveOrCopy" = false;
          };
        };
      };
      
      # ============================================================================
      # DATA FILES - File di configurazione aggiuntivi
      # ============================================================================
      dataFile = {
        # Profilo Konsole personalizzato
        "konsole/Profile 1.profile" = {
          text = ''
            [Appearance]
            ColorScheme=BreezeDark
            Font=FiraCode Nerd Font Mono,12,-1,5,50,0,0,0,0,0
            
            [General]
            Name=Profile 1
            Parent=FALLBACK/
            TerminalColumns=120
            TerminalRows=30
            
            [Scrolling]
            HistoryMode=2
            HistorySize=10000
            ScrollBarPosition=2
            
            [Terminal Features]
            BlinkingCursorEnabled=true
            UrlHintsModifiers=0
          '';
        };
      };
    };
    
    # ============================================================================
    # ADDITIONAL KDE PACKAGES
    # ============================================================================
    home.packages = with pkgs; [
      # KDE utilities
      kdePackages.yakuake           # Drop-down terminal
      kdePackages.kcalc             # Calculator
      kdePackages.kcolorchooser     # Color picker
      kdePackages.kdialog           # Dialog boxes for scripts
      kdePackages.kwalletmanager    # Wallet manager
      kdePackages.ark               # Archive manager
      kdePackages.kgpg              # GPG encryption
      kdePackages.kmag              # Screen magnifier
      kdePackages.kruler            # Screen ruler
      kdePackages.kompare           # Diff viewer
      
      # Temi e personalizzazione
      kdePackages.breeze-gtk        # GTK theme integration
      kdePackages.breeze-icons      # Icon theme
    ] ++ lib.optionals (hostname == "slimbook") [
      kdePackages.kdeconnect-kde    # Phone integration
    ];
  };
}
