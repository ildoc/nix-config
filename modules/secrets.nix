{
  config,
  pkgs,
  lib,
  ...
}:

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
        sopsFile = ../secrets/id_ed25519.enc; # File criptato separato
      };

      # WireGuard config - da file binario separato (solo per slimbook)
      "wireguard_config" = lib.mkIf (config.networking.hostName == "slimbook") {
        mode = "0400";
        owner = "root";
        group = "root";
        # RIMUOVI il path personalizzato per lasciare che SOPS usi il default
        # path = "/etc/wireguard/wg0.conf";
        format = "binary";
        sopsFile = ../secrets/wg0.conf.enc; # File criptato separato
      };
    };
  };

  # Directory necessarie
  systemd.tmpfiles.rules = [
    "d /home/filippo/.ssh 0700 filippo users -"
    "d /var/lib/sops-nix 0755 root root -"
  ]
  ++ lib.optionals (config.networking.hostName == "slimbook") [
    "d /etc/wireguard 0700 root root -"
  ];

  # ============================================================================
  # SERVIZIO PER CONFIGURAZIONE GIT
  # ============================================================================
  # Questo servizio legge l'email da sops e la configura in git
  systemd.services.setup-git-config = {
    description = "Configure Git with SOPS email";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "filippo";
      Group = "users";
      # Retry se fallisce
      Restart = "on-failure";
      RestartSec = "5s";
    };

    script = ''
      # Debug: mostra cosa abbiamo
      echo "=== Git Config Setup Debug ==="
      echo "Checking for SOPS email file..."

      # Attendi che il file segreto esista (max 60 secondi)
      count=0
      while [ ! -f ${config.sops.secrets."git/email".path} ] && [ $count -lt 60 ]; do
        echo "Waiting for SOPS email file... ($count/60)"
        sleep 1
        count=$((count + 1))
      done

      if [ ! -f ${config.sops.secrets."git/email".path} ]; then
        echo "ERROR: SOPS email file not found after 60 seconds"
        exit 1
      fi

      # Leggi l'email dal segreto
      EMAIL=$(cat ${config.sops.secrets."git/email".path} | tr -d '\n')
      echo "Found email: $EMAIL"

      # Configura git globalmente
      export HOME=/home/filippo
      ${pkgs.git}/bin/git config --file /home/filippo/.gitconfig.local user.email "$EMAIL"

      # Assicurati che il file abbia i permessi corretti
      chown filippo:users /home/filippo/.gitconfig.local
      chmod 644 /home/filippo/.gitconfig.local

      echo "Git configured successfully with email: $EMAIL"
      echo "Verification:"
      ${pkgs.git}/bin/git config --file /home/filippo/.gitconfig.local user.email
    '';
  };

  # ============================================================================
  # SERVIZIO PER SETUP SSH KEYS
  # ============================================================================
  systemd.services.setup-ssh-keys = {
    description = "Generate SSH public key from private";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Retry se fallisce
      Restart = "on-failure";
      RestartSec = "5s";
    };

    script = ''
      echo "=== SSH Keys Setup Debug ==="

      # Attendi che il file esista (max 60 secondi)
      count=0
      while [ ! -f /home/filippo/.ssh/id_ed25519 ] && [ $count -lt 60 ]; do
        echo "Waiting for SSH private key... ($count/60)"
        sleep 1
        count=$((count + 1))
      done

      if [ ! -f /home/filippo/.ssh/id_ed25519 ]; then
        echo "ERROR: SSH private key not found after 60 seconds"
        exit 1
      fi

      # Genera la chiave pubblica
      echo "Generating SSH public key..."
      ${pkgs.openssh}/bin/ssh-keygen -y -f /home/filippo/.ssh/id_ed25519 > /home/filippo/.ssh/id_ed25519.pub

      # Fix permessi
      chown filippo:users /home/filippo/.ssh/id_ed25519 /home/filippo/.ssh/id_ed25519.pub
      chmod 600 /home/filippo/.ssh/id_ed25519
      chmod 644 /home/filippo/.ssh/id_ed25519.pub

      echo "SSH keys configured successfully"
      echo "Private key: $(ls -la /home/filippo/.ssh/id_ed25519)"
      echo "Public key: $(ls -la /home/filippo/.ssh/id_ed25519.pub)"
    '';
  };

  # ============================================================================
  # SERVIZIO PER SETUP WIREGUARD CONFIG (VERSIONE AGGIORNATA)
  # ============================================================================
  systemd.services.setup-wireguard-config = lib.mkIf (config.networking.hostName == "slimbook") {
    description = "Setup WireGuard configuration for NetworkManager";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Retry se fallisce
      Restart = "on-failure";
      RestartSec = "5s";
    };

    script = ''
      echo "=== WireGuard Config Setup for NetworkManager ==="
      echo "VPN Name: ${vpnConfig.connectionName}"
      echo "Config File: ${vpnConfig.configFile}"
      echo "Interface: ${vpnConfig.interface}"
      echo "Description: ${vpnConfig.description}"

      # Attendi che il segreto esista (max 60 secondi)
      count=0
      while [ ! -f /run/secrets/wireguard_config ] && [ $count -lt 60 ]; do
        echo "Waiting for WireGuard secret... ($count/60)"
        sleep 1
        count=$((count + 1))
      done

      if [ ! -f /run/secrets/wireguard_config ]; then
        echo "ERROR: WireGuard secret not found after 60 seconds"
        exit 1
      fi

      # Crea directory WireGuard
      mkdir -p /etc/wireguard

      # Copia la configurazione (non symlink, per compatibilità NetworkManager)
      cp /run/secrets/wireguard_config /etc/wireguard/${vpnConfig.configFile}
      chmod 600 /etc/wireguard/${vpnConfig.configFile}
      chown root:root /etc/wireguard/${vpnConfig.configFile}

      # Verifica che il file sia leggibile
      if [ -r /etc/wireguard/${vpnConfig.configFile} ]; then
        echo "✓ WireGuard configuration prepared for NetworkManager"
        echo "✓ Connection name: ${vpnConfig.connectionName}"
        echo "✓ Config file: $(ls -la /etc/wireguard/${vpnConfig.configFile})"
        echo "✓ Config preview: $(head -1 /etc/wireguard/${vpnConfig.configFile})"
        echo "✓ Ready for NetworkManager import as '${vpnConfig.connectionName}'"
      else
        echo "ERROR: WireGuard configuration setup failed"
        exit 1
      fi
    '';
  };
}
