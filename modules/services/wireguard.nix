{ config, pkgs, lib, inputs, hostConfig, ... }:

let
  cfg = inputs.config;
  vpnConfig = hostConfig.vpn or null;
  isEnabled = hostConfig.features.wireguard or false;
in
{
  # ============================================================================
  # WIREGUARD OPTIONS
  # ============================================================================
  options.myConfig.vpn = {
    connectionName = lib.mkOption {
      type = lib.types.str;
      default = vpnConfig.connectionName or "office-vpn";
      description = "Nome della connessione VPN in NetworkManager";
    };
    
    configFile = lib.mkOption {
      type = lib.types.str;
      default = vpnConfig.configFile or "wg0.conf";
      description = "Nome del file di configurazione WireGuard";
    };
    
    interface = lib.mkOption {
      type = lib.types.str;
      default = vpnConfig.interface or "wg0";
      description = "Nome dell'interfaccia WireGuard";
    };
    
    description = lib.mkOption {
      type = lib.types.str;
      default = vpnConfig.description or "Office VPN Connection";
      description = "Descrizione della connessione VPN";
    };
  };

  # ============================================================================
  # WIREGUARD CONFIGURATION
  # ============================================================================
  config = lib.mkIf isEnabled {
    # Kernel module
    boot.kernelModules = [ "wireguard" ];
    
    # NetworkManager plugins
    networking.networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-openvpn
        networkmanager-l2tp
      ];
    };
    
    # Enable systemd-resolved for DNS
    services.resolved.enable = true;
    
    # ============================================================================
    # IMPORT SERVICE
    # ============================================================================
    systemd.services.import-wireguard-to-nm = {
      description = "Import WireGuard configuration to NetworkManager";
      after = [ "network-manager.service" "sops-nix.service" "setup-wireguard-config.service" ];
      wants = [ "network-manager.service" "setup-wireguard-config.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "10s";
        TimeoutStartSec = "60s";
      };
      
      script = ''
        set -e
        
        echo "=== WireGuard NetworkManager Import ==="
        echo "VPN Name: ${config.myConfig.vpn.connectionName}"
        echo "Config File: ${config.myConfig.vpn.configFile}"
        
        # Wait for NetworkManager
        count=0
        while ! ${pkgs.networkmanager}/bin/nmcli general status >/dev/null 2>&1 && [ $count -lt 30 ]; do
          echo "Waiting for NetworkManager... ($count/30)"
          sleep 2
          count=$((count + 1))
        done
        
        # Wait for config file
        count=0
        while [ ! -f /etc/wireguard/${config.myConfig.vpn.configFile} ] && [ $count -lt 60 ]; do
          echo "Waiting for WireGuard config... ($count/60)"
          sleep 1
          count=$((count + 1))
        done
        
        if [ ! -f /etc/wireguard/${config.myConfig.vpn.configFile} ]; then
          echo "ERROR: WireGuard config file not found"
          exit 1
        fi
        
        # Check if connection exists
        if ${pkgs.networkmanager}/bin/nmcli connection show "${config.myConfig.vpn.connectionName}" >/dev/null 2>&1; then
          echo "Updating existing connection..."
          ${pkgs.networkmanager}/bin/nmcli connection delete "${config.myConfig.vpn.connectionName}" || true
        fi
        
        # Import configuration
        echo "Importing WireGuard configuration..."
        ${pkgs.networkmanager}/bin/nmcli connection import type wireguard file /etc/wireguard/${config.myConfig.vpn.configFile}
        
        # Rename if necessary
        imported_name=$(basename ${config.myConfig.vpn.configFile} .conf)
        if [ "${config.myConfig.vpn.connectionName}" != "$imported_name" ]; then
          ${pkgs.networkmanager}/bin/nmcli connection modify "$imported_name" connection.id "${config.myConfig.vpn.connectionName}"
        fi
        
        # Configure for manual activation
        ${pkgs.networkmanager}/bin/nmcli connection modify "${config.myConfig.vpn.connectionName}" connection.autoconnect no
        
        echo "✓ WireGuard successfully imported into NetworkManager!"
      '';
    };
    
    # ============================================================================
    # VPN ALIASES
    # ============================================================================
    environment.shellAliases = {
      vpn-connect = "nmcli connection up '${config.myConfig.vpn.connectionName}'";
      vpn-disconnect = "nmcli connection down '${config.myConfig.vpn.connectionName}'";
      vpn-status = "nmcli connection show --active | grep '${config.myConfig.vpn.connectionName}' || echo 'VPN not connected'";
      vpn-info = "nmcli connection show '${config.myConfig.vpn.connectionName}'";
      vpn-logs = "journalctl -f -u NetworkManager | grep -i wireguard";
      wg-show = "sudo wg show";
    };
    
    # ============================================================================
    # GUI INTEGRATION
    # ============================================================================
    environment.systemPackages = with pkgs; [
      kdePackages.plasma-nm  # NetworkManager applet for KDE
      networkmanagerapplet   # Advanced NetworkManager features
    ];
  };
}
