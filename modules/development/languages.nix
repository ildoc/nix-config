{ pkgs, ... }:

let
  # Combina multiple versioni di .NET
  dotnetCombined = with pkgs.dotnetCorePackages; combinePackages [
    sdk_8_0    # LTS
    sdk_9_0    # Current
  ];
in
{
  environment.systemPackages = with pkgs; [
    # Languages and runtimes
    nodejs_22
    python3
    python3Packages.pip
    go
    
    # .NET Development - Versione combinata
    dotnetCombined
    
    # Build tools
    gnumake
    cmake
    gcc
    
    # Librerie necessarie per .NET
    icu
    openssl
    zlib
  ];
  
  # Variabili d'ambiente per .NET
  environment.variables = {
    DOTNET_ROOT = "${dotnetCombined}";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    # Disabilita il messaggio di benvenuto
    DOTNET_NOLOGO = "1";
  };
}
