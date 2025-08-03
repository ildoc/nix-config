{ config, pkgs, lib, ... }:

let
  # IP del server TrueNAS
  truenasIP = "192.168.0.123";
  
  # Rete di casa
  homeNetwork = "192.168.0.0/24";
in
{
  # Abilita il supporto NFS
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true;  # Necessario per NFS
  
  # Crea il mount point
  systemd.tmpfiles.rules = [
    "d /mnt/truenas 0755 root root -"
    "d /mnt/truenas/foto 0755 root root -"
  ];
  
  # Mount automatico con systemd quando sei sulla rete di casa
  systemd.mounts = [{
    description = "TrueNAS Foto Share";
    what = "${truenasIP}:/mnt/data/foto";
    where = "/mnt/truenas/foto";
    type = "nfs";
    options = "noauto,x-systemd.automount,x-systemd.idle-timeout=60,noatime,rsize=131072,wsize=131072";
    
    # Mount solo quando sei connesso alla rete
    unitConfig = {
      ConditionPathExists = "/sys/class/net/wlp3s0";  # Modifica con la tua interfaccia di rete
    };
  }];
  
  systemd.automounts = [{
    description = "Automount TrueNAS Foto Share";
    where = "/mnt/truenas/foto";
    wantedBy = [ "multi-user.target" ];
    
    # Timeout e opzioni
    automountConfig = {
      TimeoutIdleSec = "600";  # Unmount dopo 10 minuti di inattività
    };
  }];
  
  # NetworkManager dispatcher script per verificare la rete
  environment.etc."NetworkManager/dispatcher.d/99-mount-truenas" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      # Mount NFS quando connesso alla rete di casa
      
      interface=$1
      action=$2
      
      TRUENAS_IP="${truenasIP}"
      HOME_NETWORK="${homeNetwork}"
      
      check_home_network() {
        # Ottieni l'IP corrente
        current_ip=$(ip -4 addr show $interface | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        
        if [ -z "$current_ip" ]; then
          return 1
        fi
        
        # Verifica se sei sulla rete di casa
        if ip route get $TRUENAS_IP | grep -q "dev $interface"; then
          return 0
        else
          return 1
        fi
      }
      
      case "$action" in
        up)
          if check_home_network; then
            logger "Connected to home network, mounting TrueNAS shares"
            systemctl start mnt-truenas-foto.mount
          fi
          ;;
        down)
          logger "Network down, unmounting TrueNAS shares"
          systemctl stop mnt-truenas-foto.mount
          ;;
      esac
    '';
  };
  
  # Opzionale: Alias per accesso rapido
  environment.shellAliases = {
    nas-foto = "cd /mnt/truenas/foto";
  };
}
