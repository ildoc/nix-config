{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Languages and runtimes
    nodejs_22
    python3
    python3Packages.pip
    go
    dotnet-sdk_8
    
    # Build tools
    gnumake
    cmake
    gcc
  ];
}
