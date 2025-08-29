{ config, pkgs, lib, inputs, globalConfig, hostConfig, ... }:

let
  cfg = globalConfig;
  devCfg = cfg.development;
  
  # Combina versioni .NET
  dotnetCombined = with pkgs.dotnetCorePackages; combinePackages (
    map (v: 
      if v == "8.0" then sdk_8_0
      else if v == "9.0" then sdk_9_0
      else throw "Unsupported .NET version: ${v}"
    ) devCfg.dotnet.versions
  );
  
  # Node.js version selector
  nodejsPackage = 
    if devCfg.nodejs.version == "20" then pkgs.nodejs_20
    else if devCfg.nodejs.version == "22" then pkgs.nodejs_22
    else pkgs.nodejs;
in
{
  # ============================================================================
  # PROGRAMMING LANGUAGES
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Languages
    nodejsPackage
    python3
    python3Packages.pip
    go
    
    # .NET Development
    dotnetCombined
    
    # Db Clients
    postgresql
    sqlite
    dbeaver

    # Build tools
    gnumake
    cmake
    gcc
    
    # Libraries
    icu
    openssl
    zlib
  ] ++ cfg.packages.development.tools;

  # ============================================================================
  # ENVIRONMENT VARIABLES
  # ============================================================================
  environment.variables = {
    DOTNET_ROOT = "${dotnetCombined}";
    DOTNET_CLI_TELEMETRY_OPTOUT = if devCfg.dotnet.telemetryOptOut then "1" else "0";
    DOTNET_NOLOGO = "1";
    DOCKER_BUILDKIT = if devCfg.docker.enableBuildkit then "1" else "0";
    COMPOSE_DOCKER_CLI_BUILD = if devCfg.docker.enableBuildkit then "1" else "0";
  };

  # ============================================================================
  # DOCKER
  # ============================================================================
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    
    autoPrune = {
      enable = true;
      dates = devCfg.docker.pruneSchedule;
      flags = [ "--all" ];
    };
    
    # Per server, configurazioni aggiuntive
    logDriver = lib.mkIf (hostConfig.type == "server") "json-file";
    extraOptions = lib.mkIf (hostConfig.type == "server") ''
      --log-opt max-size=10m
      --log-opt max-file=3
    '';
  };

  # ============================================================================
  # DEVELOPMENT FIREWALL PORTS
  # ============================================================================
  networking.firewall.allowedTCPPorts = with cfg.ports.development; [
    common
    alternate
    additional
  ];

  # ============================================================================
  # APPIMAGE SUPPORT
  # ============================================================================
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # ============================================================================
  # DEVELOPMENT ALIASES
  # ============================================================================
  environment.shellAliases = {
    # Node/npm
    ni = "npm install";
    nr = "npm run";
    ns = "npm start";
    nt = "npm test";
    
    # Python
    py = "python3";
    pip = "python3 -m pip";
    venv = "python3 -m venv";
    activate = "source venv/bin/activate";
    
    # .NET
    dn = "dotnet";
    dnr = "dotnet run";
    dnb = "dotnet build";
    dnt = "dotnet test";
    dnw = "dotnet watch";
    
    # Docker compose shortcuts
    dcu = "docker-compose up";
    dcd = "docker-compose down";
    dcl = "docker-compose logs";
    dce = "docker-compose exec";
    
    # Git workflow
    gf = "git fetch";
    gfa = "git fetch --all";
    gpu = "git pull upstream";
    gpo = "git push origin";
    gr = "git rebase";
    gri = "git rebase -i";
    grc = "git rebase --continue";
    gra = "git rebase --abort";
  };

  # ============================================================================
  # USER GROUPS
  # ============================================================================
  users.users.filippo.extraGroups = [ "docker" ];
}
