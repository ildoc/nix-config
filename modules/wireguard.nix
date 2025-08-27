# modules/wireguard.nix - versione semplificata
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
      after = [ "network.target" "sops-nix.service" ];
      wants = [ "network.target" ];
      # wantedBy = [ "multi-user.target" ];  # Decommenta per auto-start
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.wireguard-tools}/bin/wg-quick up /etc/wireguard/wg0.conf";
        ExecStop = "${pkgs.wireguard-tools}/bin/wg-quick down /etc/wireguard/wg0.conf";
      };
    };
    
    # Aliases
    environment.shellAliases = {
      vpn-up = "sudo systemctl start wg-quick-wg0";
      vpn-down = "sudo systemctl stop wg-quick-wg0";
      vpn-status = "sudo systemctl status wg-quick-wg0";
      vpn-show = "sudo wg show wg0";
    };
  };
}
