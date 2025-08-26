{ config, pkgs, lib, hostname ? "", ... }:

let
  isDesktop = hostname == "slimbook" || hostname == "gaming";
  
  # Percorsi dei wallpaper
  wallpapers = {
    slimbook = ../assets/wallpapers/slimbook.jpg;
    gaming = ../assets/wallpapers/gaming.jpg;
  };
  
  # Wallpaper di default se non esiste quello specifico
  currentWallpaper = wallpapers.${hostname} or ../assets/wallpapers/default.jpg;
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
                    "applications:org.kde.konsole.desktop"     # Konsole
                    "applications:firefox.desktop"             # Firefox
                    "applications:org.telegram.desktop.desktop" # Telegram
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
                  dateFormat = "shortDate";
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
        
        # RIPRISTINATE shortcuts Spectacle per screenshot
        "services/org.kde.spectacle.desktop" = {
          "RectangularRegionScreenShot" = "Print";              # Print per ritagliare regione
          "CurrentMonitorScreenShot" = "Meta+Print";            # Meta+Print per monitor corrente
          "FullScreenScreenShot" = "Shift+Print";               # Shift+Print per schermo intero
        };
      };
      
      # ============================================================================
      # KWIN - Window Manager configurations
      # ============================================================================
      kwin = {
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
        
        # Bordi dello schermo
        borderlessMaximizedWindows = true;
        
        # Night Color (filtro luce blu)
        nightLight = {
          enable = true;
          mode = "location";
          location = {
            latitude = "44.4056";
            longitude = "8.9463";
          };
          temperature = {
            day = 6500;
            night = 4500;
          };
        };
      };
      
      # ============================================================================
      # CONFIGURAZIONI FILE CONFIG
      # ============================================================================
      configFile = {
        # Power Devil - Gestione energetica
        "powermanagementprofilesrc" = {
          # Profilo AC (corrente)
          "AC/DPMSControl" = {
            "idleTime" = 600;  # Dim dopo 10 minuti
          };
          
          "AC/DimDisplay" = {
            "idleTime" = 600;  # 10 minuti
          };
          
          "AC/SuspendSession" = {
            "idleTime" = 1800;  # 30 minuti per spegnimento schermo
            "suspendType" = 8;  # 8=turn off screen
          };
          
          # Profilo batteria (solo laptop)
          "Battery/DimDisplay" = lib.mkIf (hostname == "slimbook") {
            "idleTime" = 300;  # 5 minuti
          };
          
          "Battery/SuspendSession" = lib.mkIf (hostname == "slimbook") {
            "idleTime" = 600;  # 10 minuti
            "suspendType" = 1;  # 1=sleep
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
        
        # Effetti KWin
        "kwinrc" = {
          "Plugins" = {
            "blurEnabled" = true;
            "contrastEnabled" = true;
            "desktopgridEnabled" = true;
            "presentwindowsEnabled" = true;
            "slideEnabled" = true;
          };
          
          "Windows" = {
            "BorderlessMaximizedWindows" = true;
            "FocusPolicy" = "Click";
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
        };
        
        # Konsole settings
        "konsolerc" = {
          "Desktop Entry" = {
            "DefaultProfile" = "BreezeDark.profile";
          };
          
          "MainWindow" = {
            "MenuBar" = "Disabled";
          };
        };
        
        # Spectacle
        "spectaclerc" = {
          "General" = {
            "autoSaveImage" = true;
            "clipboardGroup" = "PostScreenshotCopyImage";
            "compressionQuality" = 90;
            "copyPathToClipboard" = false;
            "copySaveLocation" = true;
            "launchAction" = 2;  # 0=Do nothing, 1=Open With, 2=Open Containing Folder
            "rememberLastRectangularSelection" = true;
            "showMagnifierChecked" = true;  # Mostra magnifier per selezione precisa
            "useReleaseToCapture" = true;   # Cattura al rilascio del mouse
          };
          
          "GuiConfig" = {
            "captureMode" = 1;               # 1 = rectangular region (default)
            "captureOnClick" = false;
            "includeDecorations" = false;    # Non includere decorazioni finestre
            "includePointer" = false;        # Non includere puntatore mouse
            "includeShadow" = false;         # Non includere ombre
            "quitAfterSaveOrCopy" = false;   # Non chiudere dopo salvataggio
            "showCaptureInstructions" = true;
            "transientOnly" = false;
          };
          
          "Save" = {
            "defaultSaveLocation" = "file:///home/filippo/Pictures/Screenshots";
            "lastSaveLocation" = "file:///home/filippo/Pictures/Screenshots";
            "saveFilenameFormat" = "Screenshot_%Y%M%d_%H%m%S";
          };
        };
      };
    };
    
    # ============================================================================
    # ADDITIONAL KDE PACKAGES
    # ============================================================================
    home.packages = with pkgs; [
      # KDE utilities
      kdePackages.yakuake           # Drop-down terminal
      kdePackages.ark               # Archive manager
      
      # Temi e personalizzazione
      kdePackages.breeze-gtk        # GTK theme integration
      kdePackages.breeze-icons      # Icon theme
    ] ++ lib.optionals (hostname == "slimbook") [
      kdePackages.kdeconnect-kde    # Phone integration
    ];
  };
}
