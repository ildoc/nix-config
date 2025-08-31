# NixOS Configuration

Configurazione NixOS modulare e DRY (Don't Repeat Yourself) per gestire multiple macchine con minima duplicazione.

## 🚀 Quick Start

### Setup iniziale

1. **Clona il repository**:
   ```bash
   cd ~
   git clone https://gitlab.local.ildoc.it/ildoc/nix-config.git
   cd nix-config
   ```

2. **Copia hardware configuration**:
   ```bash
   sudo cp /etc/nixos/hardware-configuration.nix hosts/laptop/slimbook/
   ```

3. **Posiziona la chiave Age per SOPS**:
   ```bash
   mkdir -p ~/.config/sops/age
   # Copia la tua chiave in ~/.config/sops/age/keys.txt
   ```

4. **Link simbolico per /etc/nixos**:
   ```bash
   sudo rm -rf /etc/nixos/*
   sudo ln -s ~/nix-config/flake.nix /etc/nixos/flake.nix
   ```

5. **Rebuild del sistema**:
   ```bash
   sudo nixos-rebuild switch --flake .#slimbook
   ```

## 📁 Struttura

```
.
├── flake.nix                 # Entry point principale
├── config/
│   └── default.nix          # TUTTE le configurazioni centralizzate
├── profiles/                # Profili per tipo di macchina
│   ├── base.nix            # Configurazioni comuni a tutti
│   ├── laptop.nix          # Specifiche laptop (TLP, power management)
│   ├── desktop.nix         # Specifiche desktop
│   └── server.nix          # Specifiche server (no GUI)
├── hosts/                   # Configurazioni host-specific
│   ├── laptop/
│   │   └── slimbook/       
│   │       ├── default.nix            # Override e pacchetti specifici
│   │       └── hardware-configuration.nix
│   ├── desktop/
│   │   └── gaming/
│   └── server/
│       └── dev-server/
├── modules/                 # Moduli funzionali
│   ├── core/               # Sistema base (locale, nix, shell, security)
│   ├── desktop/            # Desktop environment (KDE, audio, fonts)
│   ├── development/        # Strumenti sviluppo (.NET, Node, Docker)
│   ├── gaming/             # Ottimizzazioni gaming (Steam, GameMode)
│   └── services/           # Servizi opzionali (WireGuard, VS Code Server)
├── users/
│   └── filippo/
│       ├── default.nix     # Definizione utente sistema
│       ├── home.nix        # Home Manager (shell tools, git, zsh)
│       └── plasma.nix      # Configurazione KDE Plasma
└── secrets/                # File criptati con SOPS
    ├── secrets.yaml        # Secrets generali
    ├── id_ed25519.enc     # Chiave SSH
    └── wg0.conf.enc       # Config WireGuard
```

## 🎯 Filosofia Zero Duplicazioni

### Dove vanno le cose:

1. **Configurazioni globali** → `config/default.nix`
   - Porte, paths, temi, settings condivisi
   - Metadata degli host (tipo, features, hardware)
   - NON pacchetti (per evitare duplicazioni)

2. **Pacchetti di sistema**:
   - **Base/comuni** → `profiles/base.nix`
   - **Desktop comuni** → `modules/desktop/default.nix`
   - **Development comuni** → `modules/development/default.nix`
   - **Gaming** → `modules/gaming/default.nix`
   - **Host-specific** → `hosts/*/default.nix` (es: teams, insomnia per slimbook)

3. **Pacchetti utente**:
   - **Shell tools** → `users/filippo/home.nix`
   - **KDE utilities** → `users/filippo/plasma.nix`

### Gerarchia override:
```
config/default.nix (variabili)
    ↓
profiles/*.nix (configurazioni tipo)
    ↓
modules/*/*.nix (features opzionali)
    ↓
hosts/*/*/default.nix (override finali + pacchetti specifici)
```

## 🔧 Comandi Utili

### Operazioni base
```bash
# Test configurazione (senza applicare)
sudo nixos-rebuild test --flake .#slimbook

# Applica configurazione
sudo nixos-rebuild switch --flake .#slimbook

# Rollback
sudo nixos-rebuild switch --rollback
```

### Diagnostica
```bash
# Esegui diagnostica completa
./scripts/diagnose.sh

# Verifica struttura flake
nix flake show

# Check configurazione
nix flake check

# Valuta opzione specifica
nix eval .#nixosConfigurations.slimbook.config.networking.hostName
```

### Manutenzione
```bash
# Aggiorna tutti i flake inputs
nix flake update

# Aggiorna solo nixpkgs
nix flake update nixpkgs

# Pulizia sistema
sudo nix-collect-garbage -d
sudo nix-store --optimise
```

### Gestione secrets
```bash
# Modifica secrets
sops secrets/secrets.yaml

# Cripta nuovo file
sops -e secrets/plaintext.conf > secrets/encrypted.enc
```

## 🎨 Personalizzazione

### Aggiungere un nuovo host

1. Crea directory: `hosts/<tipo>/<nome>/`
2. Copia `hardware-configuration.nix`
3. Crea `default.nix` con solo override specifici:
   ```nix
   { config, pkgs, ... }:
   {
     imports = [ ./hardware-configuration.nix ];
     networking.hostName = "nuovo-host";
     
     # Pacchetti specifici per questo host
     environment.systemPackages = with pkgs; [
       applicazione-specifica
     ];
   }
   ```
4. Aggiungi definizione in `config/default.nix` → `hosts`
5. Aggiungi entry in `flake.nix`

### Aggiungere pacchetti

- **Per tutti i desktop**: `modules/desktop/default.nix`
- **Per tutti i laptop**: `profiles/laptop.nix`
- **Per un host specifico**: `hosts/<tipo>/<nome>/default.nix`
- **Per l'utente (CLI)**: `users/filippo/home.nix`

## 🐛 Troubleshooting

### "not of type package"
**Problema**: Stai passando stringhe invece di pacchetti.
**Soluzione**: Usa `with pkgs; [ firefox ]` non `[ "firefox" ]`

### Pacchetto non trovato
**Problema**: Nome pacchetto errato.
**Soluzione**: 
```bash
# Cerca il nome corretto
nix search nixpkgs firefox
```

### Modifiche non applicate
**Problema**: Cache o generazione vecchia.
**Soluzione**:
```bash
# Forza rebuild
sudo nixos-rebuild switch --flake .#slimbook --option eval-cache false
```

## 📚 Documentazione

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Dettagli architettura e patterns
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Plasma Manager](https://github.com/nix-community/plasma-manager)

## 📝 Note

- La chiave Age deve essere in `~/.config/sops/age/keys.txt`
- I wallpaper vanno in `assets/wallpapers/`
- Git email viene configurata automaticamente da SOPS dopo il primo boot
- SSH keys vengono generate dal servizio systemd usando la chiave privata da SOPS
