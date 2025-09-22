# NixOS Maintenance Script - Documentazione

## 📋 Indice

- [Introduzione](#introduzione)
- [Installazione](#installazione)
- [Opzioni Globali](#opzioni-globali)
- [Comandi Disponibili](#comandi-disponibili)
  - [Comandi Principali](#comandi-principali)
  - [Gestione Configurazione](#gestione-configurazione)
  - [Gestione Aggiornamenti](#gestione-aggiornamenti)
  - [Manutenzione Sistema](#manutenzione-sistema)
- [Workflow Consigliati](#workflow-consigliati)
- [Esempi Pratici](#esempi-pratici)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## 🚀 Introduzione

Lo script `nixos-maintenance.sh` è uno strumento completo per la gestione e manutenzione di sistemi NixOS con configurazioni basate su flakes. Fornisce un'interfaccia semplificata per operazioni comuni come aggiornamenti, test, rollback e pulizia del sistema.

### Caratteristiche Principali

- **Modalità automatica**: Flag `-y` per operazioni non interattive
- **Output configurabile**: Modalità verbose per debugging
- **Workflow sicuro**: Test → Switch invece di Boot per applicazioni immediate
- **Gestione intelligente**: Opzioni sicure di default in modalità automatica
- **Logging completo**: Tutti gli output vengono salvati per analisi

## 📦 Installazione

Lo script è già incluso nel repository. Per renderlo eseguibile:

```bash
chmod +x nixos-maintenance.sh
```

### Dipendenze

Lo script verifica automaticamente le dipendenze richieste:
- `nix` - Sistema di package management
- `jq` - Parser JSON per metadata dei flakes

Se mancanti, lo script suggerirà come installarle.

## 🎛️ Opzioni Globali

Le opzioni globali devono essere specificate **prima** del comando:

| Opzione | Alias | Descrizione | Esempio |
|---------|-------|-------------|---------|
| `-y` | `--yes`, `--assume-yes` | Risponde automaticamente "sì" a tutte le conferme | `./nixos-maintenance.sh -y update` |
| `-v` | `--verbose` | Mostra output dettagliato e informazioni di debug | `./nixos-maintenance.sh -v test` |
| `-h` | `--help` | Mostra il messaggio di aiuto | `./nixos-maintenance.sh --help` |

### Comportamento del flag `-y`

Quando si usa `-y`, lo script:
- **Salta tutte le conferme** procedendo automaticamente
- **Usa opzioni sicure** di default (es. mantiene 3 generazioni in `clean`)
- **Non interrompe** per input utente
- **Ideale per automazione** e script CI/CD

## 📚 Comandi Disponibili

### Comandi Principali

#### `update`
Aggiorna il sistema con un workflow completo e sicuro.

**Workflow:**
1. Aggiorna flake inputs (`nix flake update`)
2. Dry-build per verificare la configurazione
3. Test della configurazione (temporaneo)
4. Switch per applicare permanentemente

**Uso:**
```bash
./nixos-maintenance.sh update        # Interattivo
./nixos-maintenance.sh -y update     # Automatico
./nixos-maintenance.sh -v update     # Con output dettagliato
```

**Note:**
- Usa `switch` invece di `boot` per applicazione immediata
- Mostra diff dei flake inputs prima di procedere
- Salva log in `/tmp/nixos-build.log` in caso di errori

---

#### `quick` (alias: `update-quick`, `quick-update`)
Aggiornamento rapido che salta la fase di test.

**Workflow:**
1. Aggiorna flake inputs
2. Switch diretto della configurazione

**Uso:**
```bash
./nixos-maintenance.sh quick
./nixos-maintenance.sh -y quick  # Senza conferme
```

**⚠️ Attenzione:** Più veloce ma meno sicuro di `update`.

---

#### `check` (alias: `status`)
Mostra informazioni dettagliate sul sistema.

**Informazioni mostrate:**
- Versione NixOS e kernel
- Generazioni (corrente e totali)
- Spazio occupato da Nix store
- Stato dei flake inputs
- Comandi utili suggeriti

**Uso:**
```bash
./nixos-maintenance.sh check
```

---

#### `clean`
Pulisce il sistema rimuovendo generazioni vecchie e ottimizzando lo store.

**Opzioni disponibili:**
1. Mantieni ultime 3 generazioni (default con `-y`)
2. Mantieni ultima settimana
3. Mantieni solo generazione corrente
4. Numero personalizzato di generazioni

**Uso:**
```bash
./nixos-maintenance.sh clean      # Interattivo
./nixos-maintenance.sh -y clean   # Usa opzione 1 (sicura)
```

**Operazioni eseguite:**
- Elimina generazioni secondo l'opzione scelta
- Garbage collection
- Ottimizzazione store (deduplicazione)
- Report spazio liberato

### Gestione Configurazione

#### `test`
Testa la configurazione senza renderla permanente.

**Caratteristiche:**
- Configurazione attiva fino al riavvio
- Utile per verificare modifiche rischiose
- Non modifica la generazione di boot

**Uso:**
```bash
./nixos-maintenance.sh test
./nixos-maintenance.sh -v test  # Output dettagliato
```

---

#### `switch`
Applica la configurazione immediatamente e permanentemente.

**Differenze da `boot`:**
- Applica subito senza riavvio
- Aggiorna tutti i servizi possibili
- Diventa la configurazione corrente

**Uso:**
```bash
./nixos-maintenance.sh switch
./nixos-maintenance.sh -y switch  # Senza conferma
```

---

#### `boot`
Imposta la configurazione per il prossimo boot.

**Caratteristiche:**
- Non applica immediatamente
- Richiede riavvio per attivazione
- Più sicuro per modifiche critiche

**Uso:**
```bash
./nixos-maintenance.sh boot
```

---

#### `build` (alias: `dry-build`)
Costruisce la configurazione senza applicarla.

**Utilità:**
- Verifica che la configurazione compili
- Crea il link `./result` alla build
- Non modifica il sistema

**Uso:**
```bash
./nixos-maintenance.sh build
```

---

#### `diff`
Mostra le differenze tra il sistema attuale e una nuova build.

**Informazioni mostrate:**
- Pacchetti aggiunti/rimossi/aggiornati
- Versioni cambiate
- Statistiche totali dei cambiamenti

**Uso:**
```bash
./nixos-maintenance.sh diff
```

### Gestione Aggiornamenti

#### `update-check`
Controlla aggiornamenti disponibili senza applicarli.

**Informazioni mostrate:**
- Inputs con aggiornamenti disponibili
- Differenza in giorni dall'ultima versione
- Commit hash attuali vs disponibili

**Uso:**
```bash
./nixos-maintenance.sh update-check
```

---

#### `changelog`
Mostra i commit recenti del branch nixpkgs in uso.

**Caratteristiche:**
- Rileva automaticamente il branch (stable/unstable)
- Mostra ultimi 20 commit significativi
- Include link per approfondimenti

**Uso:**
```bash
./nixos-maintenance.sh changelog
```

### Manutenzione Sistema

#### `rollback`
Torna a una generazione precedente del sistema.

**Opzioni:**
- Default: generazione precedente
- Specifica numero generazione
- Con `-y` usa il default automaticamente

**Uso:**
```bash
./nixos-maintenance.sh rollback       # Interattivo
./nixos-maintenance.sh -y rollback    # Torna alla precedente
```

**Note:** Richiede riavvio per applicazione completa.

---

#### `repair`
Verifica e ripara l'integrità dello store Nix.

**Operazioni:**
- Verifica checksums dei file
- Ripara percorsi corrotti
- Ricostruisce database se necessario

**Uso:**
```bash
./nixos-maintenance.sh repair
./nixos-maintenance.sh -y repair  # Senza conferma
```

## 🔄 Workflow Consigliati

### Aggiornamento Sicuro (Consigliato)

```bash
# 1. Controlla aggiornamenti disponibili
./nixos-maintenance.sh update-check

# 2. Vedi cosa cambierà
./nixos-maintenance.sh diff

# 3. Aggiorna con test
./nixos-maintenance.sh update

# 4. Se problemi, rollback
./nixos-maintenance.sh rollback
```

### Aggiornamento Automatico (CI/CD)

```bash
#!/bin/bash
# Script per aggiornamento automatico

# Aggiorna senza interazione
./nixos-maintenance.sh -y update

# Se fallisce, notifica
if [ $? -ne 0 ]; then
    echo "Aggiornamento fallito!" | mail -s "NixOS Update Failed" admin@example.com
fi
```

### Manutenzione Periodica

```bash
# Settimanale: controlla aggiornamenti
./nixos-maintenance.sh update-check

# Mensile: aggiorna e pulisci
./nixos-maintenance.sh -y update
./nixos-maintenance.sh -y clean

# Trimestrale: pulizia profonda
./nixos-maintenance.sh clean  # Scegli opzione 2 o 3
```

## 💡 Esempi Pratici

### Aggiornamento Completo Non-Interattivo

```bash
# Perfetto per cron job o automazione
./nixos-maintenance.sh -y update && ./nixos-maintenance.sh -y clean
```

### Test Modifiche Rischiose

```bash
# Modifica configurazione
nano /etc/nixos/configuration.nix

# Test senza rendere permanente
./nixos-maintenance.sh -v test

# Se tutto ok, applica
./nixos-maintenance.sh switch

# Altrimenti, riavvia per tornare alla configurazione precedente
```

### Debug Problemi di Build

```bash
# Build con output completo
./nixos-maintenance.sh -v build

# Se fallisce, controlla il log
tail -100 /tmp/nixos-build.log

# Prova dry-build per più dettagli
nixos-rebuild dry-build --flake .#$(hostname) --show-trace
```

### Gestione Spazio Disco

```bash
# Controlla spazio occupato
./nixos-maintenance.sh check

# Pulizia conservativa
./nixos-maintenance.sh -y clean  # Mantiene 3 generazioni

# Pulizia aggressiva (interattiva)
./nixos-maintenance.sh clean  # Scegli opzione 3
```

## 🔧 Troubleshooting

### Errori Comuni

#### "Dry-build fallito"
```bash
# Controlla errori di sintassi
nix flake check

# Verifica con trace completo
nixos-rebuild dry-build --flake .#$(hostname) --show-trace

# Controlla il log
cat /tmp/nixos-build.log | grep -i error
```

#### "Switch fallito dopo test riuscito"
```bash
# Possibile problema con servizi
journalctl -xe

# Prova boot invece di switch
./nixos-maintenance.sh boot
# Poi riavvia
```

#### "Spazio insufficiente durante update"
```bash
# Pulisci prima di aggiornare
./nixos-maintenance.sh -y clean

# Riprova aggiornamento
./nixos-maintenance.sh update
```

#### "Rollback non funziona"
```bash
# Verifica generazioni disponibili
sudo nix-env --profile /nix/var/nix/profiles/system --list-generations

# Rollback manuale a generazione specifica
sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation <numero>
```

### Log e Debug

Tutti i comandi salvano log in `/tmp/`:
- `/tmp/nixos-build.log` - Build e dry-build
- `/tmp/nixos-test.log` - Test
- `/tmp/nixos-switch.log` - Switch
- `/tmp/nixos-boot.log` - Boot

Per debug dettagliato:
```bash
# Usa sempre -v per output completo
./nixos-maintenance.sh -v <comando>

# Tail del log durante esecuzione
tail -f /tmp/nixos-*.log
```

## ✅ Best Practices

### 1. Test Prima di Switch
Sempre usa `update` invece di `quick` per modifiche importanti:
```bash
./nixos-maintenance.sh update  # Include test
```

### 2. Mantieni Generazioni di Backup
Non usare pulizia aggressiva in produzione:
```bash
./nixos-maintenance.sh -y clean  # Mantiene 3 generazioni (sicuro)
```

### 3. Documenta le Modifiche
Prima di aggiornare, committa le modifiche:
```bash
git add -A
git commit -m "feat: aggiungi servizio X"
./nixos-maintenance.sh update
```

### 4. Automazione Sicura
Per cron job, usa sempre `-y` con gestione errori:
```bash
#!/bin/bash
set -e
./nixos-maintenance.sh -y update || {
    echo "Update failed" | logger -t nixos-maintenance
    exit 1
}
```

### 5. Monitoraggio Post-Update
Dopo aggiornamenti importanti:
```bash
# Verifica servizi
systemctl --failed

# Controlla log
journalctl -p err -b

# Verifica generazione
./nixos-maintenance.sh check
```

### 6. Backup Configurazione
Prima di modifiche maggiori:
```bash
# Backup della configurazione
tar -czf ~/nixos-backup-$(date +%Y%m%d).tar.gz /etc/nixos/

# Procedi con modifiche
./nixos-maintenance.sh update
```

## 📊 Tabella Riassuntiva Comandi

| Comando | Flag -y | Riavvio | Permanente | Uso Tipico |
|---------|---------|---------|------------|------------|
| `update` | ✅ | ❌ | ✅ | Aggiornamenti regolari |
| `quick` | ✅ | ❌ | ✅ | Aggiornamenti rapidi |
| `test` | ❌ | ❌ | ❌ | Test modifiche |
| `switch` | ✅ | ❌ | ✅ | Applica configurazione |
| `boot` | ✅ | ✅ | ✅ | Modifiche critiche |
| `build` | ❌ | ❌ | ❌ | Verifica build |
| `clean` | ✅ | ❌ | ✅ | Pulizia spazio |
| `rollback` | ✅ | ✅ | ✅ | Ripristino emergenza |

## 🔗 Link Utili

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [Repository Configurazione](https://gitlab.local.ildoc.it/ildoc/nix-config)
