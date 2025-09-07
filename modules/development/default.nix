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
  # PROGRAMMING LANGUAGES AND TOOLS
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Languages
    nodejsPackage
    python3
    python3Packages.pip
    go
    
    # .NET Development
    dotnetCombined
    
    # Databases (solo CLI tools - GUI in desktop/packages.nix)
    postgresql
    sqlite
    
    # API tools (solo CLI - GUI in desktop/packages.nix)
    curl
    httpie

    # Build tools
    gnumake
    cmake
    gcc
    
    # Container tools (già in core/packages.nix se development enabled)
    # docker e docker-compose sono gestiti da virtualisation.docker
    
    # Libraries
    icu
    openssl
    zlib
  ];

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
  # USER GROUPS
  # ============================================================================
  users.users.filippo.extraGroups = [ "docker" ];
}
