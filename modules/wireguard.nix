# modules/wireguard.nix - versione corretta con auto-start
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
    
    # Usa wg-quick con il file di configurazione da sops
    systemd.services.wg-quick-wg0 = {
      description = "WireGuard Tunnel - wg0";
      after = [ "network-online.target" "sops-nix.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];  # AUTO-START ABILITATO
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Aggiungi restart automatico in caso di errore
        Restart = "on-failure";
        RestartSec = "5s";
        
        # Script di avvio
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/sleep 2 && ${pkgs.wireguard-tools}/bin/wg-quick up /etc/wireguard/wg0.conf'";
        ExecStop = "${pkgs.wireguard-tools}/bin/wg-quick down /etc/wireguard/wg0.conf";
        
        # Importante: permetti al servizio di fallire se la rete non è pronta
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'while [ ! -f /etc/wireguard/wg0.conf ]; do sleep 1; done'";
        
        # Variables d'ambiente
        Environment = [
          "WG_QUICK_USERSPACE_IMPLEMENTATION=boringtun"
        ];
      };
      
      # Dipende dal segreto wireguard
      unitConfig = {
        ConditionPathExists = "/etc/wireguard/wg0.conf";
      };
    };
    
    # Servizio di controllo stato VPN (opzionale ma utile)
    systemd.services.wireguard-status = {
      description = "Check WireGuard Status";
      after = [ "wg-quick-wg0.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.wireguard-tools}/bin/wg show || echo \"WireGuard not active\"'";
        StandardOutput = "journal";
      };
    };
    
    # Timer per controllare lo stato ogni 5 minuti (opzionale)
    systemd.timers.wireguard-status = {
      description = "Check WireGuard Status Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "5min";
        Persistent = true;
      };
    };
    
    # Aliases utili
    environment.shellAliases = {
      vpn-up = "sudo systemctl start wg-quick-wg0";
      vpn-down = "sudo systemctl stop wg-quick-wg0";
      vpn-restart = "sudo systemctl restart wg-quick-wg0";
      vpn-status = "sudo systemctl status wg-quick-wg0";
      vpn-show = "sudo wg show";
      vpn-logs = "sudo journalctl -u wg-quick-wg0 -f";
    };
    
    # Firewall: permetti traffico WireGuard
    networking.firewall = {
      # Porte per WireGuard (modifica secondo la tua config)
      allowedUDPPorts = [ 51820 ];  # Porta standard WireGuard
      
      # Opzionale: abilita forwarding se hai bisogno di routing
      # allowedTCPPorts = [ ];
    };
    
    # Configurazione di rete avanzata (opzionale)
    networking = {
      # Abilita IP forwarding se necessario
      # nat.enable = true;
      # nat.internalInterfaces = ["wg0"];
      # nat.externalInterface = "wlp3s0";  # La tua interfaccia WiFi
    };
    
    # Servizio di debug per troubleshooting
    systemd.services.wireguard-debug = {
      description = "WireGuard Debug Info";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "wg-debug" ''
          echo "=== WireGuard Debug Info ===" 
          echo "Config file exists: $([ -f /etc/wireguard/wg0.conf ] && echo 'YES' || echo 'NO')"
          echo "Config file permissions: $(ls -la /etc/wireguard/wg0.conf 2>/dev/null || echo 'FILE NOT FOUND')"
          echo "WireGuard module loaded: $(lsmod | grep -q wireguard && echo 'YES' || echo 'NO')"
          echo "Network interfaces:"
          ${pkgs.iproute2}/bin/ip link show | grep -E "(wg0|wlp)"
          echo "WireGuard status:"
          ${pkgs.wireguard-tools}/bin/wg show || echo "No WireGuard interfaces found"
          echo "Service status:"
          systemctl is-active wg-quick-wg0 || echo "Service not active"
        ''}";
        StandardOutput = "journal";
      };
    };
  };
}
