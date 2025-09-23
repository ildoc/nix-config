{
  config,
  pkgs,
  lib,
  globalConfig,
  hostConfig,
  ...
}:

let
  cfg = globalConfig;
in
{
  # ============================================================================
  # SOPS-NIX CONFIGURATION
  # ============================================================================
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    age = {
      keyFile = cfg.paths.sopsKeyFile;
      generateKey = false;
    };

    secrets = {
      # Git email - sempre presente
      "git/email" = {
        mode = "0400";
        owner = config.users.users.filippo.name;
        group = config.users.users.filippo.group;
      };

      # SSH private key - sempre presente
      "ssh_private_key" = {
        mode = "0600";
        owner = config.users.users.filippo.name;
        group = config.users.users.filippo.group;
        path = "/home/filippo/.ssh/id_ed25519";
        format = "binary";
        sopsFile = ../../secrets/id_ed25519.enc;
      };

      # WireGuard config - solo se abilitato
      "wireguard_config" = lib.mkIf (hostConfig.features.wireguard or false) {
        mode = "0400";
        owner = "root";
        group = "root";
        format = "binary";
        sopsFile = ../../secrets/wg0.conf.enc;
      };
    };
  };

  # ============================================================================
  # DIRECTORY CREATION
  # ============================================================================
  systemd.tmpfiles.rules = [
    "d /home/filippo/.ssh 0700 filippo users -"
    "d /var/lib/sops-nix 0755 root root -"
  ]
  ++ lib.optionals (hostConfig.features.wireguard or false) [
    "d /etc/wireguard 0700 root root -"
  ];

  # ============================================================================
  # GIT CONFIG SERVICE
  # ============================================================================
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
      Restart = "on-failure";
      RestartSec = "5s";
    };

    script = ''
      set -e

      # Wait for secret file
      count=0
      while [ ! -f ${config.sops.secrets."git/email".path} ] && [ $count -lt 60 ]; do
        sleep 1
        count=$((count + 1))
      done

      if [ ! -f ${config.sops.secrets."git/email".path} ]; then
        echo "ERROR: SOPS email file not found after 60 seconds"
        exit 1
      fi

      # Read email and configure git
      EMAIL=$(cat ${config.sops.secrets."git/email".path} | tr -d '\n')
      export HOME=/home/filippo
      ${pkgs.git}/bin/git config --file /home/filippo/.gitconfig.local user.email "$EMAIL"

      # Fix permissions
      chown filippo:users /home/filippo/.gitconfig.local
      chmod 644 /home/filippo/.gitconfig.local

      echo "Git configured successfully with email: $EMAIL"
    '';
  };

  # ============================================================================
  # SSH KEYS SERVICE
  # ============================================================================
  systemd.services.setup-ssh-keys = {
    description = "Generate SSH public key from private";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5s";
    };

    script = ''
      # Wait for private key
      count=0
      while [ ! -f /home/filippo/.ssh/id_ed25519 ] && [ $count -lt 60 ]; do
        sleep 1
        count=$((count + 1))
      done

      if [ ! -f /home/filippo/.ssh/id_ed25519 ]; then
        echo "ERROR: SSH private key not found after 60 seconds"
        exit 1
      fi

      # Generate public key
      ${pkgs.openssh}/bin/ssh-keygen -y -f /home/filippo/.ssh/id_ed25519 > /home/filippo/.ssh/id_ed25519.pub

      # Fix permissions
      chown filippo:users /home/filippo/.ssh/id_ed25519 /home/filippo/.ssh/id_ed25519.pub
      chmod 600 /home/filippo/.ssh/id_ed25519
      chmod 644 /home/filippo/.ssh/id_ed25519.pub

      echo "SSH keys configured successfully"
    '';
  };

  # ============================================================================
  # WIREGUARD CONFIG SERVICE
  # ============================================================================
  # ============================================================================
  # WIREGUARD CONFIG SERVICE
  # ============================================================================
  systemd.services.setup-wireguard-config = lib.mkIf (hostConfig.features.wireguard or false) {
    description = "Setup WireGuard configuration";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];

    # IMPORTANTE: Non riavviare durante switch
    restartIfChanged = false;
    reloadIfChanged = false;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Rimuovi il Restart automatico che causa loop
      # Restart = "on-failure";
      # RestartSec = "5s";

      # Aggiungi condizioni per evitare esecuzione quando non necessario
      ConditionPathExists = "/run/secrets/wireguard_config";
    };

    script = ''
      # Check if config already exists and is valid
      if [ -f /etc/wireguard/${hostConfig.vpn.configFile or "wg0.conf"} ]; then
        echo "WireGuard configuration already exists, checking if update needed..."
        
        # Solo copia se il file sorgente è più recente
        if [ /run/secrets/wireguard_config -nt /etc/wireguard/${
          hostConfig.vpn.configFile or "wg0.conf"
        } ]; then
          echo "Updating WireGuard configuration..."
          cp /run/secrets/wireguard_config /etc/wireguard/${hostConfig.vpn.configFile or "wg0.conf"}
          chmod 600 /etc/wireguard/${hostConfig.vpn.configFile or "wg0.conf"}
          chown root:root /etc/wireguard/${hostConfig.vpn.configFile or "wg0.conf"}
        else
          echo "WireGuard configuration is up to date"
        fi
      else
        echo "Creating WireGuard configuration..."
        mkdir -p /etc/wireguard
        cp /run/secrets/wireguard_config /etc/wireguard/${hostConfig.vpn.configFile or "wg0.conf"}
        chmod 600 /etc/wireguard/${hostConfig.vpn.configFile or "wg0.conf"}
        chown root:root /etc/wireguard/${hostConfig.vpn.configFile or "wg0.conf"}
      fi

      echo "WireGuard configuration ready"
    '';
  };
}
