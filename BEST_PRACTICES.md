# NixOS Configuration Best Practices

## 🏗️ Principi Architetturali

### DRY (Don't Repeat Yourself)
- **Configurazioni centralizzate** in `config/default.nix`
- **Pacchetti base** organizzati per categoria nei moduli core
- **Settings condivisi** tra host tramite `globalConfig` e `hostConfig`
- **Template riutilizzabili** per profili (laptop/desktop/server)

### Modularità
- **Un modulo = una funzionalità** (networking, audio, power, etc.)
- **Imports condizionali** basati su features dell'host
- **Separazione hardware/software** per massima riusabilità
- **Profili composabili** che importano solo i moduli necessari

## 📁 Organizzazione File

```
├── config/default.nix          # Configurazioni centralizzate
├── modules/
│   ├── core/                   # Funzionalità base (sempre presenti)
│   │   ├── packages.nix        # Pacchetti base + aliases
│   │   └── ...
│   ├── desktop/                # Desktop environment
│   │   ├── packages.nix        # Applicazioni desktop
│   │   └── ...
│   └── hardware/               # Configurazioni hardware
│       ├── power.nix           # Power management coordinato
│       └── ...
├── profiles/                   # Template per tipi di macchine
│   ├── base.nix               # Configurazione base comune
│   ├── laptop.nix             # Specifico per laptop
│   └── ...
├── hosts/                     # Configurazioni specifiche per host
└── users/                     # Configurazioni utente (Home Manager)
```

## ⚡ Power Management

### Problema Risolto: Conflitti TLP/KDE
**Sintomi**: Audio che si disconnette ciclicamente, schermo acceso dopo logout

**Soluzione**:
1. **TLP configurato** per gestire CPU, batteria, PCIe
2. **USB Autosuspend disabilitato** (`USB_AUTOSUSPEND = 0`)
3. **Runtime PM disabilitato** (`RUNTIME_PM_ON_BAT = "off"`)
4. **Sound Power Saving disabilitato** (`SOUND_POWER_SAVE_ON_BAT = 0`)
5. **KDE PowerDevil coordinato** con timeout più lunghi di TLP
6. **Logind** gestisce solo lid switch e lock screen

### File Coinvolti
- `modules/hardware/power.nix` - Configurazioni TLP centralizzate
- `users/filippo/plasma.nix` - PowerDevil coordinato con TLP
- `config/default.nix` - Timeout centralizzati

## 📦 Gestione Pacchetti

### Principi
- **Pacchetti veri, non stringhe**: `with pkgs; [ firefox ]` non `[ "firefox" ]`
- **Conditional imports**: `lib.optionals (condition) [ packages ]`
- **Categorizzazione**: core, desktop, development, gaming
- **Excludes esplicite**: rimuovi pacchetti indesiderati di KDE

### Struttura
```nix
environment.systemPackages = with pkgs; [
  # Essentials - sempre presenti
  firefox
  git
  
] ++ lib.optionals (hostConfig.features.gaming) [
  # Gaming - solo se abilitato
  steam
  lutris
  
] ++ lib.optionals (hostConfig.type == "laptop") [
  # Laptop - tools specifici
  powertop
  acpi
];
```

## 🖥️ Desktop Configuration

### KDE + Home Manager
- **Plasma Manager** per configurazioni KDE dichiarative
- **Theme centralizzato** in `config/default.nix`
- **Wallpaper per host** selezionati automaticamente
- **Taskbar dinamica** basata su `hostConfig.taskbar.pinned`

### Night Light
- **Coordinate geografiche** centralizzate
- **Temperature automatiche** giorno/notte
- **Integrazione location services** per cambio automatico

## 🔧 Debugging Tools

### Makefile Commands
```bash
make quick-check    # Check veloce del sistema
make power-status   # Stato power management
make audio-status   # Stato sistema audio
make rebuild        # Rebuild configurazione
make test          # Test senza commit
```

### Troubleshooting Audio
```bash
# Check servizi attivi
systemctl --user status pipewire
pactl info

# Check TLP settings
tlp-stat -s

# Monitor USB events
sudo journalctl -f | grep -i usb
```

### Troubleshooting Power
```bash
# Verifica conflitti power management
systemctl is-active tlp power-profiles-daemon

# Log power events
journalctl -u tlp.service
journalctl -u systemd-logind
```

## 🚀 Aggiungere Nuovo Host

1. **Creare directory host**:
   ```bash
   mkdir -p hosts/[profile]/[hostname]
   ```

2. **Definire in config/default.nix**:
   ```nix
   hosts.[hostname] = {
     type = "laptop|desktop|server";
     hardware = { ... };
     features = { ... };
   };
   ```

3. **Aggiungere al flake.nix**:
   ```nix
   [hostname] = mkHost {
     hostname = "[hostname]";
     profile = "[profile]";
   };
   ```

## 🔐 Secrets Management

### Workflow SOPS
1. **Generate age key**: `age-keygen -o ~/.config/sops/age/keys.txt`
2. **Add to .sops.yaml**: configurare chiavi per file
3. **Edit secrets**: `sops secrets/secrets.yaml`
4. **Reference in config**: `config.sops.secrets.[name].path`

### Best Practices
- **Un file secrets per ambiente** (staging/production)
- **Keys specifiche per host** quando necessario
- **Rotation regolare** delle chiavi sensibili

## 📊 Monitoring & Maintenance

### Updates
```bash
make update    # Update flake inputs
make check     # Verify configuration
make rebuild   # Apply changes
```

### Cleanup
```bash
make clean           # Garbage collection
nix-store --optimize # Deduplicate store
```

### Health Checks
- **Weekly**: `make quick-check`
- **Monthly**: Update flake inputs
- **Quarterly**: Review e cleanup configurazioni obsolete
