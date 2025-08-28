{ config, pkgs, lib, ... }:

{
  # Configurazione sops-nix per gestione segreti
  sops = {
    # File YAML per segreti testuali (email, ecc.)
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    
    # Chiave Age per decriptare
    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = false;
    
    # Definizione dei segreti
    secrets = {
      # ====================================================================
      # SEGRETI DA FILE YAML (secrets.yaml)
      # ====================================================================
      
      # Git email - dal file YAML
      "git/email" = {
        mode = "0400";
        owner = config.users.users.filippo.name;
        group = config.users.users.filippo.group;
        # Usa defaultSopsFile (secrets.yaml)
      };
      
      # ====================================================================
      # SEGRETI DA FILE BINARI SEPARATI (.enc)
      # ====================================================================
      
      # SSH private key - da file binario separato
      "ssh_private_key" = {
        mode = "0600";
        owner = config.users.users.filippo.name;
        group = config.users.users.filippo.group;
        path = "/home/filippo/.ssh/id_ed25519";
        format = "binary";
        sopsFile = ../secrets/id_ed25519.enc;  # File criptato separato
      };
      
      # WireGuard config - da file binario separato (solo per slimbook)
      "wireguard_config" = lib.mkIf (config.networking.hostName == "slimbook") {
        mode = "0400";
        owner = "root";
        group = "root";
        path = "/etc/wireguard/wg0.conf";
        format = "binary";
        sopsFile = ../secrets/wg0.conf.enc;  # File criptato separato
      };
    };
  };
  
  # Directory necessarie
  systemd.tmpfiles.rules = [
    "d /home/filippo/.ssh 0700 filippo users -"
    "d /var/lib/sops-nix 0755 root root -"
  ] ++ lib.optionals (config.networking.hostName == "slimbook") [
    "d /etc/wireguard 0700 root root -"
  ];
  
  # Servizio per generare la chiave pubblica SSH
  systemd.services.setup-ssh-keys = {
    description = "Generate SSH public key from private";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    
    script = ''
      # Attendi che il file esista
      while [ ! -f /home/filippo/.ssh/id_ed25519 ]; do
        sleep 1
      done
      
      # Genera la chiave pubblica
      if [ -f /home/filippo/.ssh/id_ed25519 ]; then
        ${pkgs.openssh}/bin/ssh-keygen -y -f /home/filippo/.ssh/id_ed25519 > /home/filippo/.ssh/id_ed25519.pub
        chown filippo:users /home/filippo/.ssh/id_ed25519.pub
        chmod 644 /home/filippo/.ssh/id_ed25519.pub
        
        # Fix permessi chiave privata
        chown filippo:users /home/filippo/.ssh/id_ed25519
        chmod 600 /home/filippo/.ssh/id_ed25519
      fi
    '';
  };
}
