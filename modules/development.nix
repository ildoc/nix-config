{ config, pkgs, ... }:

{
  # ============================================================================
  # CONFIGURAZIONE AMBIENTE DI SVILUPPO
  # ============================================================================
  # Strumenti e configurazioni per sviluppo software
  # Modulo condiviso tra desktop e server di sviluppo

  # === LINGUAGGI DI PROGRAMMAZIONE ===
  environment.systemPackages = with pkgs; [
    # === RUNTIME E SDK ===
    nodejs_22               # Node.js LTS più recente
    python3                 # Python 3 runtime
    python3Packages.pip     # Package manager Python
    go                      # Go language runtime
    dotnet-sdk_8           # .NET 8 SDK (LTS)
    
    # === DATABASES ===
    postgresql              # Database relazionale
    sqlite                  # Database embedded
    
    # === BUILD TOOLS ===
    gnumake                 # Make build system
    cmake                   # Cross-platform build system
    gcc                     # GNU Compiler Collection
    
    # === API E NETWORK TOOLS ===
    postman                 # GUI API testing
    curl                    # Command line HTTP client
    httpie                  # Modern HTTP client
    
    # === CONTAINER TOOLS ===
    docker                  # Container runtime
    docker-compose          # Multi-container orchestration
    
    # === DATA PROCESSING ===
    jq                      # JSON processor
    yq                      # YAML processor
    
  ] ++ (
    # === IDE CONDIZIONALI PER HOST ===
    # Installa IDE pesanti solo dove necessario
    let
      hostname = config.networking.hostName;
    in
    if hostname == "slimbook" then [
      unstable.jetbrains.rider # IDE per .NET (versione più recente)
      vscode                   # Visual Studio Code
    ] else if hostname == "gaming" then [
      vscode                   # Solo VS Code per gaming rig
    ] else [
      # Server: nessun IDE GUI
    ]
  );

  # === VIRTUALIZZAZIONE DOCKER ===
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    
    # === CONFIGURAZIONI OTTIMIZZATE ===
    # Pulizia automatica per evitare accumulo di immagini
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
  };
  
  # === PERMESSI UTENTE ===
  # Aggiungi filippo al gruppo docker per uso senza sudo
  users.users.filippo.extraGroups = [ "docker" ];
  
  # === VARIABILI D'AMBIENTE SVILUPPO ===
  environment.variables = {
    # === DOCKER OPTIMIZATION ===
    DOCKER_BUILDKIT = "1";           # Abilita BuildKit per build più veloci
    COMPOSE_DOCKER_CLI_BUILD = "1";  # Usa Docker CLI per Compose
    
    # === DEVELOPMENT PATHS ===
    # GOPATH sarà impostato automaticamente da Go
    # NODE_ENV non viene impostato globalmente (dipende dal progetto)
  };

  # === CONFIGURAZIONI AGGIUNTIVE ===
  
  # Abilita supporto per AppImage (utile per alcune applicazioni di sviluppo)
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  
  # === SERVICES SVILUPPO ===
  # Questi servizi possono essere abilitati per host specifici se necessario
  
  # PostgreSQL locale per sviluppo (commentato per default)
  # services.postgresql = {
  #   enable = true;
  #   package = pkgs.postgresql_15;
  #   authentication = pkgs.lib.mkOverride 10 ''
  #     local all all trust
  #     host all all 127.0.0.1/32 trust
  #     host all all ::1/128 trust
  #   '';
  #   initialScript = pkgs.writeText "backend-initScript" ''
  #     CREATE ROLE filippo WITH LOGIN PASSWORD 'password' CREATEDB;
  #     CREATE DATABASE filippo;
  #     GRANT ALL PRIVILEGES ON DATABASE filippo TO filippo;
  #   '';
  # };
  
  # Redis locale per sviluppo (commentato per default)
  # services.redis = {
  #   enable = true;
  #   servers."" = {
  #     enable = true;
  #     port = 6379;
  #   };
  # };
}
