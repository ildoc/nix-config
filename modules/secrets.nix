{ config, pkgs, lib, ... }:

{
  # Configurazione sops-nix per gestione segreti
  sops = {
    # File dei segreti criptati (lo creeremo dopo)
    defaultSopsFile = ../secrets/secrets.yaml;
    
    # Formato del file segreti
    defaultSopsFormat = "yaml";
    
    # Percorso della chiave age sul sistema
    # IMPORTANTE: Questa chiave NON va nel repository!
    age.keyFile = "/var/lib/sops-nix/key.txt";
    
    # Auto genera la chiave se non esiste (solo per il primo setup)
    age.generateKey = false;
    
    # Definizione dei segreti
    secrets = {
      # SSH private key per l'utente filippo
      "ssh_keys/filippo_ed25519" = {
        mode = "0600";
        owner = config.users.users.filippo.name;
        group = config.users.users.filippo.group;
        # Path dove verrà montato il segreto decriptato
        path = "/home/filippo/.ssh/id_ed25519";
      };
      
      # Git email - verrà usato come variabile d'ambiente
      "git/email" = {
        mode = "0400";
        owner = config.users.users.filippo.name;
        group = config.users.users.filippo.group;
      };
      
      "wireguard/wg0.conf" = lib.mkIf (config.networking.hostName == "slimbook") {
        mode = "0400";
        owner = "root";
        group = "root";
        path = "/etc/wireguard/wg0.conf";
        format = "binary";  # IMPORTANTE: specifica formato binary
        sopsFile = ../secrets/wg0.conf.enc;  # File criptato separato
      };
    };
  };
  
  # Assicura che le directory necessarie esistano
  systemd.tmpfiles.rules = [
    "d /home/filippo/.ssh 0700 filippo users -"
    "d /var/lib/sops-nix 0755 root root -"
  ] ++ lib.optionals (config.networking.hostName == "slimbook") [
    "d /etc/wireguard 0700 root root -"
  ];
  
  # Servizio per configurare SSH dopo che i segreti sono stati decriptati
  systemd.services.setup-ssh-keys = {
    description = "Setup SSH keys from sops";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    
    script = ''
      # Assicura i permessi corretti per la directory SSH
      chown filippo:users /home/filippo/.ssh
      chmod 700 /home/filippo/.ssh
      
      # Se esiste la chiave privata, genera anche la pubblica
      if [ -f /home/filippo/.ssh/id_ed25519 ]; then
        ${pkgs.openssh}/bin/ssh-keygen -y -f /home/filippo/.ssh/id_ed25519 > /home/filippo/.ssh/id_ed25519.pub
        chown filippo:users /home/filippo/.ssh/id_ed25519.pub
        chmod 644 /home/filippo/.ssh/id_ed25519.pub
      fi
    '';
  };
  
  # WireGuard configuration usando i segreti (solo per slimbook)
  networking.wireguard = lib.mkIf (config.networking.hostName == "slimbook") {
    enable = true;
    
    interfaces = {
      wg0 = {
        # La chiave privata verrà letta dal segreto
        privateKeyFile = config.sops.secrets."wireguard/slimbook_private_key".path;
        
        # Configurazione dell'interfaccia
        # Questi valori dovrai personalizzarli
        ips = [ "10.100.0.2/32" ];
        
        peers = [
          {
            # Esempio peer - sostituisci con i tuoi valori reali
            publicKey = "PEER_PUBLIC_KEY_QUI";
            allowedIPs = [ "10.100.0.0/24" ];
            endpoint = "vpn.example.com:51820";
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };
}
