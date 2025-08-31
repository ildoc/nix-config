{ config, pkgs, lib, inputs, globalConfig, hostname, hostConfig, ... }:

let
  cfg = globalConfig;
  
  # Percorsi dei wallpaper
  wallpapers = {
    slimbook = ../../assets/wallpapers/slimbook.jpg;
    gaming = ../../assets/wallpapers/gaming.jpg;
  };
  
  # Wallpaper di default se non esiste quello specifico
  currentWallpaper = wallpapers.${hostname} or ../../assets/wallpapers/default.jpg;
  
  # Applicazioni pinnate dalla configurazione (se esistono)
  pinnedApps = if hostConfig ? taskbar && hostConfig.taskbar ? pinned then
    map (app: "applications:${app}.desktop") hostConfig.taskbar.pinned
  else [];
in
{
  programs.plasma = {
    enable = true;
    
    # ============================================================================
    # WORKSPACE - Configurazioni generali del desktop
    # ============================================================================
    workspace = {
      # Tema e aspetto
      lookAndFeel = cfg.desktop.theme.plasma;
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
      iconTheme = cfg.desktop.theme.icons;
      
      # Wallpaper
      wallpaper = currentWallpaper;
      
      # Cursore
      cursor = {
        theme = cfg.desktop.theme.cursor.theme;
        size = cfg.desktop.theme.cursor.size;
      };
      
      # Click policy
      clickItemTo = "select";  # o "open" per single-click
    };
    
    # ============================================================================
    # PANELS - Configurazione pannelli e taskbar
    # ============================================================================
    panels = [
      {
        # Pannello principale
        location = cfg.desktop.panel.location;
        height = cfg.desktop.panel.height;
        floating = false;
        screen = 0;  # 0 = monitor principale
        
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
                launchers = pinnedApps;
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
      
      # Screenshots con Spectacle
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
      # Desktop virtuali
      virtualDesktops = {
        rows = 1;
        number = cfg.desktop.virtualDesktops.number;
        names = cfg.desktop.virtualDesktops.names;
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
          latitude = cfg.network.location.latitude;
          longitude = cfg.network.location.longitude;
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
          "idleTime" = cfg.desktop.powerManagement.ac.screenOffAfter;
        };
        
        "AC/DimDisplay" = {
          "idleTime" = cfg.desktop.powerManagement.ac.dimAfter;
        };
        
        "AC/SuspendSession" = {
          "idleTime" = cfg.desktop.powerManagement.ac.screenOffAfter;
          "suspendType" = 8;  # 8=turn off screen
        };
        
        # Profilo batteria (solo laptop)
        "Battery/DimDisplay" = lib.mkIf (hostConfig.hardware.hasBattery or false) {
          "idleTime" = cfg.desktop.powerManagement.battery.dimAfter;
        };
        
        "Battery/SuspendSession" = lib.mkIf (hostConfig.hardware.hasBattery or false) {
          "idleTime" = cfg.desktop.powerManagement.battery.suspendAfter;
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
          "Theme" = cfg.desktop.theme.plasma;
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
        
        # Configurazione Multi-Monitor
        "Xwayland" = {
          "XwaylandEavesdrops" = "None";
        };
      };
      
      # Configurazione schermi e pannelli
      "plasmashellrc" = {
        # Assicura che il pannello rimanga sul monitor principale
        "ScreenConnectors" = {
          "0" = "Primary";
        };
        
        # Configurazione per non spostare pannelli
        "PlasmaViews" = {
          "panelVisibility" = "0";  # 0 = sempre visibile
          "alignment" = "132";  # Centro
          "lockPanel" = true;  # Blocca il pannello
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
          "showMagnifierChecked" = true;
          "useReleaseToCapture" = true;
        };
        
        "GuiConfig" = {
          "captureMode" = 1;  # 1 = rectangular region (default)
          "captureOnClick" = false;
          "includeDecorations" = false;
          "includePointer" = false;
          "includeShadow" = false;
          "quitAfterSaveOrCopy" = false;
          "showCaptureInstructions" = true;
          "transientOnly" = false;
        };
        
        "Save" = {
          "defaultSaveLocation" = "file:///home/${globalConfig.users.filippo.username}/Pictures/Screenshots";
          "lastSaveLocation" = "file:///home/${globalConfig.users.filippo.username}/Pictures/Screenshots";
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
  ] ++ lib.optionals (hostConfig.features.wireguard or false) [
    kdePackages.kdeconnect-kde    # Phone integration
  ];
}
