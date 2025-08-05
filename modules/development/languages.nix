{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Languages and runtimes
    nodejs_22
    python3
    python3Packages.pip
    go
    
    # .NET Development - SDK e runtime completi
    dotnet-sdk_8
    dotnet-runtime_8
    dotnet-aspnetcore_8
    
    # MSBuild e dipendenze
    msbuild
    mono  # Necessario per alcuni progetti legacy
    
    # Build tools
    gnumake
    cmake
    gcc
    
    # Librerie aggiuntive per .NET
    icu
    openssl
    zlib
  ];
  
  # Variabili d'ambiente per .NET
  environment.variables = {
    DOTNET_ROOT = "${pkgs.dotnet-sdk_8}";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    # MSBuild potrebbe richiedere questo
    MSBuildSDKsPath = "${pkgs.dotnet-sdk_8}/sdk/${pkgs.dotnet-sdk_8.version}/Sdks";
  };
}
