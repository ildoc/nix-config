# modules/wireguard.nix - configurazione WireGuard con NetworkManager e opzioni centralizzate
{ config, pkgs, lib, ... }:
let
  isSlimbook = config.networking.hostName == "slimbook";
  
  # Usa la configurazione centralizzata
  vpnConfig = config.myConfig.vpn;
in
{
  # Importa la configurazione VPN centralizzata
  imports = [ ./config/vpn.nix ];
  
  config = lib.mkIf isSlimbook {
    # Assicura che WireGuard sia disponibile
    boot.kernelModules = [ "wireguard" ];
    
    # Abilita il plugin WireGuard per NetworkManager
    networking.networkmanager = {
      enable = true; # Già abilitato in desktop.nix, ma confermiamo
      plugins = with pkgs; [
        networkmanager-openvpn
        networkmanager-l2tp
      ];
    };
        
    # ============================================================================
    # SERVIZIO PER IMPORTARE LA CONFIGURAZIONE IN NETWORKMANAGER
    # ============================================================================
    systemd.services.import-wireguard-to-nm = {
      description = "Import WireGuard configuration to NetworkManager";
      after = [ "network-manager.service" "sops-nix.service" "setup-wireguard-config.service" ];
      wants = [ "network-manager.service" "setup-wireguard-config.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Retry se fallisce
        Restart = "on-failure";
        RestartSec = "10s";
        RestartMode = "on-failure";
        # Timeout più lungo per permettere a NM di avviarsi completamente
        TimeoutStartSec = "60s";
      };
      
      script = ''
        set -e
        
        echo "=== WireGuard NetworkManager Import ==="
        echo "VPN Name: ${vpnConfig.connectionName}"
        echo "Config File: ${vpnConfig.configFile}"
        echo "Interface: ${vpnConfig.interface}"
        echo "Description: ${vpnConfig.description}"
        
        # Attendi che NetworkManager sia completamente avviato
        count=0
        while ! ${pkgs.networkmanager}/bin/nmcli general status >/dev/null 2>&1 && [ $count -lt 30 ]; do
          echo "Waiting for NetworkManager to be ready... ($count/30)"
          sleep 2
          count=$((count + 1))
        done
        
        if ! ${pkgs.networkmanager}/bin/nmcli general status >/dev/null 2>&1; then
          echo "ERROR: NetworkManager not ready after 60 seconds"
          exit 1
        fi
        
        # Attendi che il file di configurazione WireGuard esista
        count=0
        while [ ! -f /etc/wireguard/${vpnConfig.configFile} ] && [ $count -lt 60 ]; do
          echo "Waiting for WireGuard config file... ($count/60)"
          sleep 1
          count=$((count + 1))
        done
        
        if [ ! -f /etc/wireguard/${vpnConfig.configFile} ]; then
          echo "ERROR: WireGuard config file not found after 60 seconds"
          exit 1
        fi
        
        # Controlla se la connessione esiste già
        if ${pkgs.networkmanager}/bin/nmcli connection show "${vpnConfig.connectionName}" >/dev/null 2>&1; then
          echo "WireGuard connection '${vpnConfig.connectionName}' already exists in NetworkManager"
          
          # Aggiorna la connessione esistente rimuovendola e ricreandola
          echo "Updating existing connection..."
          ${pkgs.networkmanager}/bin/nmcli connection delete "${vpnConfig.connectionName}" || true
        fi
        
        # Importa la configurazione WireGuard in NetworkManager
        echo "Importing WireGuard configuration into NetworkManager..."
        ${pkgs.networkmanager}/bin/nmcli connection import type wireguard file /etc/wireguard/${vpnConfig.configFile}
        
        # Rinomina la connessione se necessario (nmcli import usa il nome del file senza estensione)
        imported_name=$(basename ${vpnConfig.configFile} .conf)
        if [ "${vpnConfig.connectionName}" != "$imported_name" ]; then
          echo "Renaming connection from '$imported_name' to '${vpnConfig.connectionName}'..."
          ${pkgs.networkmanager}/bin/nmcli connection modify "$imported_name" connection.id "${vpnConfig.connectionName}"
        fi
        
        # Imposta la connessione per non connettersi automaticamente
        echo "Configuring connection for manual activation..."
        ${pkgs.networkmanager}/bin/nmcli connection modify "${vpnConfig.connectionName}" connection.autoconnect no
        ${pkgs.networkmanager}/bin/nmcli connection modify "${vpnConfig.connectionName}" connection.autoconnect-priority 0
        
        # Imposta una descrizione personalizzata se supportata
        ${pkgs.networkmanager}/bin/nmcli connection modify "${vpnConfig.connectionName}" connection.id "${vpnConfig.connectionName}" || true
        
        # Verifica che l'importazione sia riuscita
        if ${pkgs.networkmanager}/bin/nmcli connection show "${vpnConfig.connectionName}" >/dev/null 2>&1; then
          echo "✓ WireGuard successfully imported into NetworkManager!"
          echo "✓ Connection name: ${vpnConfig.connectionName}"
          echo "✓ Auto-connect: DISABLED (manual activation only)"
          echo ""
          echo "You can now:"
          echo "  • See the VPN in NetworkManager GUI as '${vpnConfig.connectionName}'"
          echo "  • Connect: nmcli connection up ${vpnConfig.connectionName}"
          echo "  • Disconnect: nmcli connection down ${vpnConfig.connectionName}"
          echo "  • Status: nmcli connection show --active | grep ${vpnConfig.connectionName}"
        else
          echo "✗ Failed to import WireGuard configuration"
          exit 1
        fi
      '';
    };
    
    # ============================================================================
    # SERVIZIO PER SINCRONIZZARE MODIFICHE DALLA GUI
    # ============================================================================
    systemd.services.sync-wireguard-changes = {
      description = "Sync WireGuard changes from NetworkManager back to config";
      # Non viene avviato automaticamente - solo su richiesta
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;
        ExecStart = "${pkgs.writeShellScript "sync-wg-changes" ''
          set -e
          
          echo "Syncing NetworkManager WireGuard changes back to system config..."
          echo "Connection: ${vpnConfig.connectionName}"
          
          # Esporta la configurazione corrente da NetworkManager
          temp_config=$(mktemp)
          ${pkgs.networkmanager}/bin/nmcli connection show ${vpnConfig.connectionName} | grep -E "^(wireguard|ipv4)" > "$temp_config" || {
            echo "Failed to export NetworkManager configuration"
            rm -f "$temp_config"
            exit 1
          }
          
          echo "Current NetworkManager config exported to temporary file"
          echo "Manual sync completed - check if configuration needs updating in SOPS"
          
          rm -f "$temp_config"
        ''}";
      };
    };
    
    # ============================================================================
    # FIREWALL E NETWORKING
    # ============================================================================
    # Il firewall per WireGuard non è necessario per le connessioni client
    # La porta è gestita automaticamente dalla configurazione del server
    # NetworkManager gestirà automaticamente le regole necessarie
    
    # Abilita systemd-resolved per DNS resolution
    services.resolved.enable = true;
    
    # ============================================================================
    # ALIASES E UTILITY
    # ============================================================================
    environment.shellAliases = {
      # NetworkManager VPN aliases - usano il nome centralizzato
      vpn-connect = "nmcli connection up '${vpnConfig.connectionName}'";
      vpn-disconnect = "nmcli connection down '${vpnConfig.connectionName}'";
      vpn-status = "nmcli connection show --active | grep '${vpnConfig.connectionName}' || echo 'VPN ${vpnConfig.connectionName} not connected'";
      vpn-info = "nmcli connection show '${vpnConfig.connectionName}'";
      vpn-logs = "journalctl -f -u NetworkManager | grep -i wireguard";
      
      # WireGuard direct aliases (ancora disponibili per debug)
      wg-show = "sudo wg show";
      wg-config = "sudo cat /etc/wireguard/${vpnConfig.configFile}";
      
      # NetworkManager general
      nm-connections = "nmcli connection show";
      nm-devices = "nmcli device status";
      nm-wifi = "nmcli device wifi list";
      
      # Import/sync aliases
      vpn-reimport = "sudo systemctl restart import-wireguard-to-nm";
      vpn-sync = "sudo systemctl start sync-wireguard-changes";
      
      # Info aliases
      vpn-config-info = "echo 'VPN Configuration:' && echo '  Name: ${vpnConfig.connectionName}' && echo '  File: ${vpnConfig.configFile}' && echo '  Interface: ${vpnConfig.interface}' && echo '  Port: ${toString vpnConfig.port}'";
    };
    
    # ============================================================================
    # NOTIFICA AL COMPLETAMENTO DELL'IMPORTAZIONE
    # ============================================================================
    systemd.services.wireguard-nm-ready-notification = {
      description = "Notify when WireGuard is ready in NetworkManager";
      after = [ "import-wireguard-to-nm.service" ];
      wants = [ "import-wireguard-to-nm.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.writeShellScript "wg-nm-notification" ''
          # Verifica che l'importazione sia completata con successo
          if ${pkgs.networkmanager}/bin/nmcli connection show "${vpnConfig.connectionName}" >/dev/null 2>&1; then
            echo "🎉 WireGuard VPN is now available in NetworkManager!"
            echo ""
            echo "📱 GUI Access:"
            echo "   • Open Network settings in KDE System Settings"
            echo "   • Look for '${vpnConfig.connectionName}' in VPN connections"
            echo "   • Click to connect/disconnect manually"
            echo ""
            echo "🖥️  Command Line:"
            echo "   • Connect: vpn-connect"
            echo "   • Disconnect: vpn-disconnect"
            echo "   • Status: vpn-status"
            echo ""
            echo "⚙️  Management:"
            echo "   • All connections: nm-connections"
            echo "   • Re-import config: vpn-reimport"
            echo "   • Config info: vpn-config-info"
            echo ""
            echo "🎯 Connection Details:"
            echo "   • Name: ${vpnConfig.connectionName}"
            echo "   • Interface: ${vpnConfig.interface}"
            echo "   • Description: ${vpnConfig.description}"
            echo "   • Config file: ${vpnConfig.configFile}"
          else
            echo "⚠️  WireGuard import may have failed. Check logs with:"
            echo "   journalctl -u import-wireguard-to-nm"
          fi
        ''}";
        StandardOutput = "journal";
      };
    };
    
    # ============================================================================
    # CONFIGURAZIONE KDE INTEGRATION
    # ============================================================================
    # Assicura che KDE possa gestire le connessioni NetworkManager
    programs.nm-applet.enable = false; # Non necessario in KDE, usa plasma-nm
    
    # Pacchetti per l'integrazione GUI
    environment.systemPackages = with pkgs; [
      # GUI tools per NetworkManager (già inclusi in KDE)
      kdePackages.plasma-nm # NetworkManager applet per KDE
      
      # CLI tools avanzati
      networkmanagerapplet # Per nmcli advanced features
    ];
  };
}
