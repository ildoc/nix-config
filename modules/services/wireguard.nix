{
  config,
  pkgs,
  lib,
  inputs,
  globalConfig,
  hostConfig,
  ...
}:

let
  cfg = globalConfig;
  isEnabled = hostConfig.features.wireguard or false;
in
{
  # Solo configurazione, non opzioni aggiuntive
  config = lib.mkIf isEnabled {
    # ============================================================================
    # WIREGUARD CONFIGURATION
    # ============================================================================
    # Kernel module
    boot.kernelModules = [ "wireguard" ];

    # NetworkManager plugins
    networking.networkmanager = {
      plugins = with pkgs; [
        networkmanager-openvpn
        networkmanager-l2tp
      ];
    };

    # Enable systemd-resolved for DNS
    services.resolved.enable = true;

    # ============================================================================
    # IMPORT SERVICE - FIXED TO NOT AUTO-CONNECT
    # ============================================================================
    systemd.services.import-wireguard-to-nm = {
      description = "Import WireGuard configuration to NetworkManager";
      after = [
        "network-manager.service"
        "sops-nix.service"
        "setup-wireguard-config.service"
      ];
      wants = [
        "network-manager.service"
        "setup-wireguard-config.service"
      ];
      wantedBy = [ "network-online.target" ];

      restartIfChanged = false;
      stopIfChanged = false;

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Rimuovi Restart automatico
        # Restart = "on-failure";
        # RestartSec = "10s";
        TimeoutStartSec = "60s";

        # Esegui solo se il file di configurazione esiste
        ConditionPathExists = "/etc/wireguard/${configFile}";
      };

      script =
        let
          vpnName = hostConfig.vpn.connectionName or "Wg Casa";
          configFile = hostConfig.vpn.configFile or "wg0.conf";
        in
        ''
          set -e

          echo "=== WireGuard NetworkManager Import ==="
          echo "VPN Name: ${vpnName}"
          echo "Config File: ${configFile}"

          # Wait for NetworkManager
          count=0
          while ! ${pkgs.networkmanager}/bin/nmcli general status >/dev/null 2>&1 && [ $count -lt 30 ]; do
            echo "Waiting for NetworkManager... ($count/30)"
            sleep 2
            count=$((count + 1))
          done

          # Wait for config file
          count=0
          while [ ! -f /etc/wireguard/${configFile} ] && [ $count -lt 60 ]; do
            echo "Waiting for WireGuard config... ($count/60)"
            sleep 1
            count=$((count + 1))
          done

          if [ ! -f /etc/wireguard/${configFile} ]; then
            echo "ERROR: WireGuard config file not found"
            exit 1
          fi

          # Check if connection exists
          if ${pkgs.networkmanager}/bin/nmcli connection show "${vpnName}" >/dev/null 2>&1; then
            echo "Updating existing connection..."
            ${pkgs.networkmanager}/bin/nmcli connection delete "${vpnName}" || true
          fi

          # Import configuration
          echo "Importing WireGuard configuration..."
          ${pkgs.networkmanager}/bin/nmcli connection import type wireguard file /etc/wireguard/${configFile}

          # Rename if necessary
          imported_name=$(basename ${configFile} .conf)
          if [ "${vpnName}" != "$imported_name" ]; then
            ${pkgs.networkmanager}/bin/nmcli connection modify "$imported_name" connection.id "${vpnName}"
          fi

          # CRITICAL FIX: Ensure VPN is NOT auto-connected
          echo "Configuring VPN for manual activation only..."
          ${pkgs.networkmanager}/bin/nmcli connection modify "${vpnName}" \
            connection.autoconnect no \
            connection.autoconnect-priority -999 \
            ipv4.never-default yes \
            ipv6.never-default yes

          # Additional safety: ensure it's down after import
          ${pkgs.networkmanager}/bin/nmcli connection down "${vpnName}" 2>/dev/null || true

          echo "✓ WireGuard imported and configured for manual activation only!"
          echo "Use 'vpn-connect' to manually connect when needed."
        '';
    };

    # ============================================================================
    # VPN ALIASES
    # ============================================================================
    environment.shellAliases =
      let
        vpnName = hostConfig.vpn.connectionName or "Wg Casa";
      in
      {
        vpn-connect = "nmcli connection up '${vpnName}'";
        vpn-disconnect = "nmcli connection down '${vpnName}'";
        vpn-status = "nmcli connection show --active | grep '${vpnName}' || echo 'VPN not connected'";
        vpn-info = "nmcli connection show '${vpnName}'";
        vpn-logs = "journalctl -f -u NetworkManager | grep -i wireguard";
        wg-show = "sudo wg show";
      };

    # ============================================================================
    # GUI INTEGRATION
    # ============================================================================
    environment.systemPackages = with pkgs; [
      kdePackages.plasma-nm # NetworkManager applet for KDE
      networkmanagerapplet # Advanced NetworkManager features
    ];
  };
}
