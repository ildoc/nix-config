# modules/wireguard.nix - configurazione solo setup senza auto-start
{ config, pkgs, lib, ... }:
let
  isSlimbook = config.networking.hostName == "slimbook";
in
{
  config = lib.mkIf isSlimbook {
    # Assicura che WireGuard sia disponibile
    boot.kernelModules = [ "wireguard" ];
    
    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];
    
    # Definisci il servizio WireGuard ma NON lo avviare automaticamente
    systemd.services.wg-quick-wg0 = {
      description = "WireGuard Tunnel - wg0";
      after = [ "network-online.target" "sops-nix.service" ];
      wants = [ "network-online.target" ];
      # RIMOSSO: wantedBy = [ "multi-user.target" ];  # NO AUTO-START
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        
        # Script di avvio semplificato
        ExecStart = "${pkgs.wireguard-tools}/bin/wg-quick up /etc/wireguard/wg0.conf";
        ExecStop = "${pkgs.wireguard-tools}/bin/wg-quick down /etc/wireguard/wg0.conf";
        
        # Verifica che il file di configurazione esista
        ExecStartPre = "${pkgs.bash}/bin/bash -c '[ -f /etc/wireguard/wg0.conf ] || { echo \"WireGuard config not found\"; exit 1; }'";
      };
      
      # Dipende dal segreto wireguard
      unitConfig = {
        ConditionPathExists = "/etc/wireguard/wg0.conf";
      };
    };
    
    # Previeni che NetworkManager gestisca WireGuard automaticamente
    networking.networkmanager.unmanaged = [ "wg0" ];
    
    # Aliases utili per controllo manuale
    environment.shellAliases = {
      vpn-up = "sudo systemctl start wg-quick-wg0";
      vpn-down = "sudo systemctl stop wg-quick-wg0";
      vpn-restart = "sudo systemctl restart wg-quick-wg0";
      vpn-status = "sudo systemctl status wg-quick-wg0";
      vpn-show = "sudo wg show";
      vpn-logs = "sudo journalctl -u wg-quick-wg0 -f";
      vpn-config = "sudo cat /etc/wireguard/wg0.conf";
    };
    
    # Firewall: permetti traffico WireGuard
    networking.firewall = {
      # Porte per WireGuard (modifica secondo la tua config)
      allowedUDPPorts = [ 51820 ];  # Porta standard WireGuard
    };
    
    # Servizio per verificare che la configurazione sia stata creata
    systemd.services.wireguard-setup-check = {
      description = "Check WireGuard configuration setup";
      after = [ "sops-nix.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.writeShellScript "wg-setup-check" ''
          echo "Checking WireGuard setup..."
          if [ -f /etc/wireguard/wg0.conf ]; then
            echo "✓ WireGuard config file created successfully"
            echo "✓ Use 'vpn-up' to connect or 'vpn-status' to check"
            # Verifica che la configurazione sia valida
            ${pkgs.wireguard-tools}/bin/wg-quick strip /etc/wireguard/wg0.conf > /dev/null && echo "✓ Configuration syntax is valid" || echo "✗ Configuration syntax error"
          else
            echo "✗ WireGuard config file not found"
            exit 1
          fi
        ''}";
        StandardOutput = "journal";
      };
    };
  };
}
