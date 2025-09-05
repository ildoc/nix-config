# NixOS Configuration

[![NixOS 25.05](https://img.shields.io/badge/NixOS-25.05-blue.svg?style=flat-square&logo=nixos)](https://nixos.org)
[![Flakes](https://img.shields.io/badge/Flakes-enabled-brightgreen.svg?style=flat-square)](https://nixos.wiki/wiki/Flakes)
[![SOPS](https://img.shields.io/badge/Secrets-SOPS-orange.svg?style=flat-square)](https://github.com/Mic92/sops-nix)

Configurazione modulare e DRY (Don't Repeat Yourself) per gestire multiple macchine NixOS con minima duplicazione del codice. Supporta laptop, desktop e server con gestione sicura dei segreti tramite SOPS.

## 📋 Indice

- [Caratteristiche](#-caratteristiche)
- [Requisiti](#-requisiti)
- [Setup Iniziale](#-setup-iniziale)
- [Struttura del Repository](#-struttura-del-repository)
- [Gestione Host](#-gestione-host)
- [Comandi Utili](#-comandi-utili)
- [Personalizzazione](#-personalizzazione)
- [Troubleshooting](#-troubleshooting)
- [Manutenzione](#-manutenzione)

## ✨ Caratteristiche

- **🔧 Configurazione Modulare**: Separazione tra profili (laptop/desktop/server) e moduli funzionali
- **🔐 Gestione Sicura Secrets**: Integrazione SOPS con Age per chiavi SSH, password e configurazioni sensibili
- **🏠 Home Manager**: Configurazione utente dichiarativa con Plasma Manager per KDE
- **🎮 Gaming Ready**: Supporto completo per Steam, Lutris, GameMode con ottimizzazioni kernel
- **💻 Development**: Ambiente di sviluppo completo con Docker, .NET, Node.js, Python
- **🔌 VS Code Server**: Supporto per sviluppo remoto su server
- **🌐 WireGuard VPN**: Integrazione con NetworkManager per connessioni VPN
- **⚡ Ottimizzazioni**: TLP per laptop coordinato con KDE PowerDevil, gestione energetica senza conflitti
- **🏗️ DRY Principles**: Configurazioni centralizzate, pacchetti non duplicati, settings condivisi
- **🔧 Power Management**: Configurazioni TLP e KDE coordinate per evitare conflitti audio/schermo

## 🚨 Problemi Risolti

### Power Management & Audio
- **✅ Risolto**: Conflitti tra TLP e KDE PowerDevil che causavano disconnessioni audio cicliche
- **✅ Risolto**: Schermo che rimaneva acceso dopo logout per inattività
- **✅ Configurato**: Timeout coordinati tra logind, TLP e KDE per evitare interferenze
- **✅ Disabilitato**: USB autosuspend e Runtime PM per dispositivi audio

### Centralizzazione
- **✅ Rimosso**: Pacchetti duplicati tra moduli e profili
- **✅ Centralizzato**: Configurazioni power management nel modulo `hardware/power.nix`
- **✅ Organizzato**: Pacchetti base in `core/packages.nix`, desktop in `desktop/packages.nix`
- **✅ Unificato**: Alias e shortcuts in un unico punto per manutenibilità

## 📦 Requisiti

- **NixOS 25.05** o superiore
- **Flakes** abilitati
- **Git** per clonare il repository
- **Age** per la gestione delle chiavi di cifratura

## 🚀 Setup Iniziale

### 1. Preparazione Sistema Base

```bash
# Installa NixOS con configurazione minimale
# Abilita flakes nel sistema temporaneo
sudo mkdir -p /etc/nixos
echo "{ nix.settings.experimental-features = [ \"nix-command\" \"flakes\" ]; }" | sudo tee /etc/nixos/configuration.nix
sudo nixos-rebuild switch
```

### 2. Generazione Chiave Age e Clone Repository

```bash
# Installa age
nix-shell -p age

# Genera una nuova chiave Age
age-keygen -o age-key.txt

# IMPORTANTE: Salva la chiave pubblica mostrata nell'output
# Esempio: age1rmaj7ayhvw9l8qtg6p9y8n8elt6xt6l7ng6suqvxsszlc83ycclspesfzc

# Crea la directory per la chiave
mkdir -p ~/.config/sops/age
mv age-key.txt ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# Clona il repository
cd ~
git clone https://gitlab.local.ildoc.it/ildoc/nix-config.git
cd nix-config

# IMPORTANTE: Aggiorna la chiave pubblica Age in .sops.yaml
# Sostituisci la chiave esistente con la tua chiave pubblica
nano .sops.yaml
```

### 3. Configurazione Hardware

```bash
# Genera la configurazione hardware per il tuo sistema
sudo nixos-generate-config --show-hardware-config > hardware-temp.nix

# Determina il tipo di sistema (laptop/desktop/server)
# e crea la directory appropriata
mkdir -p hosts/<tipo>/<nome-host>

# Copia la configurazione hardware
cp hardware-temp.nix hosts/<tipo>/<nome-host>/hardware-configuration.nix

# Esempio per un laptop chiamato "thinkpad":
# mkdir -p hosts/laptop/thinkpad
# cp hardware-temp.nix hosts/laptop/thinkpad/hardware-configuration.nix
```

### 4. Creazione Secrets

```bash
# Installa sops
nix-shell -p sops age ssh-to-age

# Ricrea i secrets con la tua chiave
rm secrets/*.enc

# Email Git
cat > secrets/secrets-plain.yaml << EOF
git:
    email: tua-email@example.com
EOF
sops -e secrets/secrets-plain.yaml > secrets/secrets.yaml
rm secrets/secrets-plain.yaml

# Chiave SSH (genera nuova o usa esistente)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_temp
sops -e ~/.ssh/id_ed25519_temp > secrets/id_ed25519.enc

# WireGuard (opzionale)
# sops -e wg0-temp.conf > secrets/wg0.conf.enc
```

### 5. Configurazione Nuovo Host

#### Aggiungi metadata in `config/default.nix`:

```nix
hosts = {
  thinkpad = {
    type = "laptop";  # laptop|desktop|server
    description = "ThinkPad T480 - Work laptop";
    hardware = {
      cpu = "intel";
      graphics = "intel";
      hasBattery = true;
      hasBluetooth = true;
      hasWifi = true;
    };
    features = {
      desktop = true;
      development = true;
      wireguard = false;
      gaming = false;
      vscodeServer = false;
    };
    taskbar = {
      pinned = [
        "firefox"
        "org.kde.konsole"
        "code"
        # ...
      ];
    };
  };
};
```

#### Crea `hosts/<tipo>/<nome-host>/default.nix`:

```nix
{ config, pkgs, lib, inputs, hostConfig, globalConfig, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "thinkpad";

  # Hardware specifics
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  
  hardware.enableRedistributableFirmware = true;

  # Pacchetti specifici per questo host
  environment.systemPackages = with pkgs; [
    # Aggiungi pacchetti specifici qui
  ];
}
```

#### Aggiungi al `flake.nix`:

```nix
nixosConfigurations = {
  # ...altri host...
  
  thinkpad = mkHost {
    hostname = "thinkpad";
    profile = "laptop";  # o "desktop" o "server"
    extraModules = [
      ./modules/development
      # altri moduli necessari
    ];
  };
};
```

### 6. Build e Deployment

```bash
# Link simbolico per /etc/nixos
sudo rm -rf /etc/nixos/*
sudo ln -s ~/nix-config/flake.nix /etc/nixos/flake.nix

# Test della configurazione (non applica modifiche)
sudo nixos-rebuild test --flake .#thinkpad

# Se tutto funziona, applica la configurazione
sudo nixos-rebuild switch --flake .#thinkpad

# Riavvia per assicurarti che tutto funzioni
sudo reboot
```

## 📁 Struttura del Repository

```tree
.
├── flake.nix                 # Entry point principale
├── config/
│   └── default.nix          # Configurazioni centralizzate globali
├── profiles/                # Profili per tipo di macchina
│   ├── base.nix            # Base comune a tutti
│   ├── laptop.nix          # Specifiche laptop (TLP, batteria)
│   ├── desktop.nix         # Specifiche desktop (performance)
│   └── server.nix          # Specifiche server (no GUI)
├── hosts/                   # Configurazioni host-specific
│   ├── laptop/
│   │   └── slimbook/       
│   ├── desktop/
│   │   └── gaming/
│   └── server/
│       └── dev-server/
├── modules/                 # Moduli funzionali
│   ├── core/               # Sistema base
│   ├── desktop/            # Desktop environment
│   ├── development/        # Strumenti sviluppo
│   ├── gaming/             # Gaming setup
│   └── services/           # Servizi opzionali
├── users/
│   └── filippo/
│       ├── default.nix     # Definizione utente
│       ├── home.nix        # Home Manager config
│       └── plasma.nix      # KDE Plasma settings
├── secrets/                # File criptati SOPS
└── assets/
    └── wallpapers/         # Wallpaper desktop
```

## 🖥️ Gestione Host

### Host Disponibili

| Host | Tipo | Descrizione | Features |
|------|------|-------------|----------|
| `slimbook` | Laptop | Development workstation | Desktop, Development, WireGuard |
| `gaming` | Desktop | Gaming rig | Desktop, Gaming |
| `dev-server` | Server | Headless dev server | Development, VS Code Server |

### Dove Aggiungere Pacchetti

Per evitare duplicazioni, segui questa gerarchia:

| Tipo di Pacchetto | Posizione |
|-------------------|-----------|
| Pacchetti base (tutti gli host) | `profiles/base.nix` |
| Applicazioni desktop (GUI) | `modules/desktop/default.nix` |
| Tools di sviluppo | `modules/development/default.nix` |
| Software gaming | `modules/gaming/default.nix` |
| Pacchetti specifici per host | `hosts/<tipo>/<nome>/default.nix` |
| Shell tools utente | `users/filippo/home.nix` |
| Utilità KDE | `users/filippo/plasma.nix` |

## 🛠️ Comandi Utili

### Makefile Commands

```bash
make rebuild    # Rebuild e switch configurazione
make test       # Test configurazione senza applicare
make update     # Aggiorna flake inputs
make clean      # Garbage collection e ottimizzazione
make check      # Verifica configurazione
make diff       # Mostra differenze con sistema attuale
make format     # Formatta codice Nix
make show       # Mostra struttura flake
make develop    # Entra nella dev shell
```

### Script di Manutenzione

```bash
./nixos-maintenance.sh update        # Aggiorna sistema
./nixos-maintenance.sh update-check  # Controlla aggiornamenti disponibili
./nixos-maintenance.sh clean         # Pulizia sistema
./nixos-maintenance.sh check         # Info sistema
./nixos-maintenance.sh rollback      # Rollback
./nixos-maintenance.sh changelog     # Mostra changelog
```

### Alias Shell Disponibili

```bash
# NixOS management
rebuild         # Rebuild configurazione corrente
rebuild-test    # Test configurazione
flake-update    # Aggiorna flake inputs
gc-full         # Garbage collection completa

# WireGuard (se abilitato)
vpn-connect     # Connetti VPN
vpn-disconnect  # Disconnetti VPN
vpn-status      # Stato connessione
```

## 🎨 Personalizzazione

### Modificare Configurazioni Globali

Tutte le configurazioni sono centralizzate in `config/default.nix`:

- **Sistema**: timezone, locale, stateVersion
- **Utenti**: username, gruppi, git config
- **Network**: IP TrueNAS, location per Night Color
- **Porte**: SSH, HTTP, development, gaming, KDE Connect
- **Desktop**: temi, pannelli, virtual desktops, power management
- **Development**: versioni .NET/Node.js, Docker settings
- **Gaming**: GameMode, audio, kernel parameters

### Personalizzare KDE Plasma

Modifica `users/filippo/plasma.nix` per:

- Layout pannelli e widget
- Shortcuts tastiera personalizzate
- Virtual desktops e nomi
- Effetti finestre e animazioni
- Night Color settings
- Power management profili

### Gestione Secrets con SOPS

#### Modificare secrets esistenti:
```bash
sops secrets/secrets.yaml
```

#### Aggiungere nuovo secret:
1. Definisci in `modules/core/security.nix`
2. Cifra con `sops -e file > secrets/file.enc`

#### Debugging secrets:
```bash
# Verifica decryption
sops -d secrets/secrets.yaml

# Check servizi SOPS
systemctl status sops-nix
journalctl -u setup-git-config
```

## 🐛 Troubleshooting

### Errori Comuni e Soluzioni

| Errore | Soluzione |
|--------|-----------|
| "not of type package" | Usa `with pkgs; [ firefox ]` invece di `[ "firefox" ]` |
| Chiave Age non trovata | Verifica che sia in `~/.config/sops/age/keys.txt` con permessi 600 |
| Build fallisce dopo update | `sudo nixos-rebuild switch --rollback` |
| WireGuard non si connette | Usa `vpn-connect` o `nmcli connection up "Wg Casa"` |
| Pacchetto non trovato | Cerca con `nix search nixpkgs nome-pacchetto` |

### Comandi di Debug

```bash
# Valuta configurazione specifica
nix eval .#nixosConfigurations.nome-host.config.networking.hostName

# Mostra trace completo errori
nix flake check --show-trace

# Analizza dipendenze
nix-tree ./result

# Verifica differenze
nix store diff-closures /run/current-system ./result

# Log servizi
journalctl -xe -u nome-servizio
```

## 🔧 Manutenzione

### Routine Consigliata

#### Settimanale
```bash
./nixos-maintenance.sh update-check  # Controlla aggiornamenti
make update                          # Se ci sono aggiornamenti
make test                           # Testa prima di applicare
```

#### Mensile
```bash
sudo nix-collect-garbage -d        # Pulizia generazioni vecchie
sudo nix-store --optimise          # Ottimizza store
tar -czf ~/backup-nix-$(date +%Y%m%d).tar.gz ~/nix-config
```

#### Aggiornamento Major Version
1. Backup delle generazioni: `sudo nix-env --list-generations --profile /nix/var/nix/profiles/system`
2. Modifica branch in `flake.nix`: `nixos-25.05` → `nixos-25.11`
3. Test approfondito: `nix flake update && sudo nixos-rebuild test --flake .#nome-host`
4. Se OK: `sudo nixos-rebuild switch --flake .#nome-host`

## 📚 Risorse

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Plasma Manager](https://github.com/nix-community/plasma-manager)
- [SOPS-Nix](https://github.com/Mic92/sops-nix)
- [Nix Pills](https://nixos.org/guides/nix-pills/)

## 📝 Note Importanti

- **Chiave Age**: DEVE essere in `~/.config/sops/age/keys.txt` con permessi 600
- **Secrets**: Tutti i file `.enc` devono essere ricreati con la TUA chiave Age
- **Wallpapers**: Posizionali in `assets/wallpapers/nome-host.jpg`
- **Git Email**: Viene configurata automaticamente da SOPS dopo il primo boot
- **SSH Keys**: Generate automaticamente dal servizio systemd usando SOPS
- **Compatibilità**: Sistema configurato per NixOS 25.05
