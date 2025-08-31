#!/usr/bin/env bash

# Script per applicare tutte le correzioni alla configurazione NixOS
set -e

echo "Applicando le correzioni alla configurazione NixOS..."

# Crea directory mancanti
mkdir -p assets/wallpapers

# Crea file placeholder per i wallpaper se non esistono
touch assets/wallpapers/slimbook.jpg 2>/dev/null || true
touch assets/wallpapers/gaming.jpg 2>/dev/null || true
touch assets/wallpapers/default.jpg 2>/dev/null || true

# Funzione per verificare e correggere l'ordine dei parametri
fix_module_params() {
    local file=$1
    if [ -f "$file" ]; then
        # Corregge l'ordine dei parametri nella firma della funzione
        sed -i 's/{ config, pkgs, lib, globalConfig, inputs, hostConfig/{ config, pkgs, lib, inputs, globalConfig, hostConfig/g' "$file"
        sed -i 's/{ config, lib, globalConfig, inputs, hostConfig/{ config, lib, inputs, globalConfig, hostConfig/g' "$file"
        sed -i 's/{ config, pkgs, lib, globalConfig, inputs, hostname, hostConfig/{ config, pkgs, lib, inputs, globalConfig, hostname, hostConfig/g' "$file"
        echo "✓ Fixed: $file"
    fi
}

# Correggi tutti i moduli
fix_module_params "modules/desktop/default.nix"
fix_module_params "modules/desktop/kde.nix"
fix_module_params "modules/development/default.nix"
fix_module_params "modules/gaming/default.nix"
fix_module_params "modules/services/wireguard.nix"
fix_module_params "modules/services/vscode-server.nix"
fix_module_params "modules/hardware/audio.nix"
fix_module_params "modules/hardware/bluetooth.nix"
fix_module_params "modules/hardware/graphics.nix"
fix_module_params "modules/hardware/power.nix"
fix_module_params "users/filippo/default.nix"
fix_module_params "users/filippo/home.nix"
fix_module_params "users/modules/plasma.nix"
fix_module_params "profiles/base.nix"
fix_module_params "profiles/laptop.nix"
fix_module_params "profiles/desktop.nix"
fix_module_params "profiles/server.nix"

echo ""
echo "Correzioni applicate! Ora prova:"
echo "  sudo nixos-rebuild test --flake .#slimbook --show-trace"
