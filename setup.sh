#!/usr/bin/env bash
# Setup script per configurazione NixOS

set -e

REPO_DIR="$HOME/nixos-config"
HOSTNAME=$(hostname)

echo "🚀 Setting up NixOS configuration for host: $HOSTNAME"

# Verifica che l'host sia supportato
if [[ ! -d "$REPO_DIR/hosts/$HOSTNAME" ]]; then
    echo "❌ Error: Host $HOSTNAME not found in configuration"
    echo "Available hosts:"
    ls "$REPO_DIR/hosts/"
    exit 1
fi

echo "✅ Host $HOSTNAME found in configuration"

# Backup hardware-configuration.nix se non esiste nel repo
if [[ ! -f "$REPO_DIR/hosts/$HOSTNAME/hardware-configuration.nix" ]]; then
    echo "📋 Copying hardware-configuration.nix from /etc/nixos..."
    if [[ -f "/etc/nixos/hardware-configuration.nix" ]]; then
        cp /etc/nixos/hardware-configuration.nix "$REPO_DIR/hosts/$HOSTNAME/"
        echo "✅ hardware-configuration.nix copied successfully"
    else
        echo "⚠️  Warning: /etc/nixos/hardware-configuration.nix not found"
        echo "You may need to generate it with: sudo nixos-generate-config"
    fi
else
    echo "✅ hardware-configuration.nix already exists in repo"
fi

# Backup della configurazione esistente
if [[ -f "/etc/nixos/configuration.nix" ]] && [[ ! -L "/etc/nixos/configuration.nix" ]]; then
    echo "🔄 Backing up existing /etc/nixos/configuration.nix..."
    sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup-$(date +%Y%m%d-%H%M%S)
fi

# Crea symlink flake.nix
echo "🔗 Creating flake.nix symlink..."
sudo ln -sf "$REPO_DIR/flake.nix" /etc/nixos/flake.nix
echo "✅ Symlink created: /etc/nixos/flake.nix -> $REPO_DIR/flake.nix"

# Test dry-run prima del rebuild vero
echo "🧪 Testing configuration with dry-run..."
if sudo nixos-rebuild dry-run --flake "$REPO_DIR#$HOSTNAME"; then
    echo "✅ Dry-run successful!"
    
    # Chiedi conferma per il rebuild reale
    read -p "🤔 Proceed with actual rebuild? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 Running nixos-rebuild switch..."
        sudo nixos-rebuild switch --flake "$REPO_DIR#$HOSTNAME"
        echo "🎉 Setup completed successfully!"
        echo ""
        echo "📝 Useful commands:"
        echo "  rebuild          - sudo nixos-rebuild switch --flake ~/nixos-config"
        echo "  rebuild-test     - sudo nixos-rebuild test --flake ~/nixos-config"
        echo "  flake-update     - sudo nix flake update ~/nixos-config"
        echo "  gc-full          - sudo nix-collect-garbage -d && nix-store --gc"
    else
        echo "⏭️  Skipping rebuild. You can run it manually with:"
        echo "   sudo nixos-rebuild switch --flake $REPO_DIR#$HOSTNAME"
    fi
else
    echo "❌ Dry-run failed! Please check your configuration."
    exit 1
fi
