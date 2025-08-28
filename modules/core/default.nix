{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./boot.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./security.nix
    ./shell.nix
  ];
}
