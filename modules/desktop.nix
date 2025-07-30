{ config, pkgs, ... }:

{
  # ============================================================================
  # CONFIGURAZIONE DESKTOP ENVIRONMENT
  # ============================================================================
  # Modulo per sistemi desktop con KDE Plasma 6
  # Ottimizzato per NixOS 25.05 con le nuove API

  # === X11 E DISPLAY SERVER ===
  services.xserver = {
    enable = true;
    
    # Configurazione tastiera italiana
    xkb = {
      layout = "it";
      variant = "";
      options = "numlock:on"; # Num Lock attivo all'avvio
    };
  };
  
  # === DESKTOP ENVIRONMENT ===
  # KDE Plasma 6 - Ambiente desktop moderno e completo
  services.desktopManager.plasma6.enable = true;
  
  # === DISPLAY MANAGER ===
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true; # Supporto Wayland per il futuro
    };
  };
  
  # === SISTEMA AUDIO ===
  # PipeWire - audio server moderno (default su NixOS 25.05)
  services.pulseaudio.enable = false; # Disabilita PulseAudio legacy
  
  security.rtkit.enable = true; # Real-time kit per audio a bassa latenza
  
  services.pipewire = {
    enable = true;
    
    # Compatibilità con ALSA
    alsa = {
      enable = true;
      support32Bit = true; # Supporto applicazioni 32-bit
    };
    
    # Compatibilità PulseAudio
    pulse.enable = true;
  };

  # === NETWORK MANAGEMENT ===
  networking.networkmanager.enable = true;
  
  # Aggiungi utente al gruppo per gestione network
  users.users.filippo.extraGroups = [ "networkmanager" ];

  # === SERVIZI DI STAMPA ===
  services.printing.enable = true;

  # === CONFIGURAZIONE FONT ===
  fonts.packages = with pkgs; [
    # === FONT DI SISTEMA ===
    noto-fonts              # Font Unicode completo di Google
    noto-fonts-cjk-sans     # Supporto lingue asiatiche
    noto-fonts-emoji        # Emoji

    # === FONT LIBERI ===
    liberation_ttf          # Alternative libere a Arial, Times, Courier

    # === FONT PER SVILUPPO ===
    fira-code               # Font monospace con ligature
    fira-code-symbols       # Simboli aggiuntivi
    source-code-pro         # Font monospace di Adobe
    source-sans-pro         # Font sans-serif di Adobe

    # === FONT PER DESIGN ===
    font-awesome            # Icone vettoriali
  ];

  # === APPLICAZIONI DESKTOP ESSENZIALI ===
  environment.systemPackages = with pkgs; [
    # === BROWSER E COMUNICAZIONE ===
    firefox                 # Browser principale
    telegram-desktop        # Messaging

    prismlauncher

    # === EDITOR E IDE ===
    vscode                  # Editor di codice universale
    
    # === MULTIMEDIA ===
    vlc                     # Player video universale
    spotify                 # Streaming musicale
    
    # === APPLICAZIONI KDE PLASMA 6 ===
    kdePackages.kate        # Editor di testo avanzato
    kdePackages.dolphin     # File manager
    kdePackages.spectacle   # Screenshot tool
    kdePackages.okular      # Visualizzatore PDF
    kdePackages.gwenview    # Visualizzatore immagini
    kdePackages.konsole     # Terminale KDE
    
    # === UTILITIES SISTEMA ===
    dconf-editor            # Editor configurazioni GNOME/GTK
  ];

  # === OTTIMIZZAZIONE KDE ===
  # Rimuovi applicazioni KDE non necessarie per ridurre bloat
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa                   # Player musicale (usiamo Spotify)
    khelpcenter            # Centro aiuto (raramente usato)
  ];
  
  # === INTEGRAZIONE MOBILE ===
  # KDE Connect per sincronizzazione con dispositivi Android/iOS
  programs.kdeconnect.enable = true;

  # === FIREWALL PER KDE CONNECT ===
  # Porte necessarie per la comunicazione con dispositivi mobili
  networking.firewall = {
    allowedTCPPorts = [ 
      # Range porte KDE Connect
      1714 1715 1716 1717 1718 1719 1720 1721 1722 1723 1724 
    ];
    allowedUDPPorts = [ 
      # Range porte KDE Connect  
      1714 1715 1716 1717 1718 1719 1720 1721 1722 1723 1724 
    ];
  };
}
