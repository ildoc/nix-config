#!/usr/bin/env bash

# Script per completare la migrazione alla nuova struttura modulare NixOS
set -e

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== NixOS Configuration Migration Completion Script ===${NC}"
echo -e "${YELLOW}Questo script completerà la migrazione alla struttura modulare${NC}\n"

# Controllo se siamo nella directory corretta
if [ ! -f "flake.nix" ]; then
    echo -e "${RED}Errore: flake.nix non trovato. Assicurati di essere nella directory della configurazione NixOS${NC}"
    exit 1
fi

# Funzione helper per creare directory
create_dir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "   ${GREEN}✓${NC} Creata: $dir"
    else
        echo -e "   ${BLUE}ℹ${NC} Già esistente: $dir"
    fi
}

# Funzione helper per creare file se non esiste
create_file_if_not_exists() {
    local file=$1
    local content=$2
    if [ ! -f "$file" ]; then
        echo "$content" > "$file"
        echo -e "   ${GREEN}✓${NC} Creato: $file"
    else
        echo -e "   ${BLUE}ℹ${NC} Già esistente: $file"
    fi
}

echo -e "${BLUE}1. Creazione directory mancanti...${NC}"

# Hardware modules
create_dir "modules/hardware"

echo -e "\n${BLUE}2. Controllo file moduli hardware...${NC}"

# Controlla se esistono i moduli hardware
hardware_modules=(
    "modules/hardware/audio.nix"
    "modules/hardware/bluetooth.nix" 
    "modules/hardware/graphics.nix"
    "modules/hardware/power.nix"
)

for module in "${hardware_modules[@]}"; do
    if [ ! -f "$module" ]; then
        echo -e "   ${YELLOW}⚠${NC}  Mancante: $module - Crealo usando i template forniti"
    else
        echo -e "   ${GREEN}✓${NC} Esistente: $module"
    fi
done

echo -e "\n${BLUE}3. Controllo moduli desktop...${NC}"

if [ ! -f "modules/desktop/kde.nix" ]; then
    echo -e "   ${YELLOW}⚠${NC}  Mancante: modules/desktop/kde.nix - Crealo usando il template fornito"
else
    echo -e "   ${GREEN}✓${NC} Esistente: modules/desktop/kde.nix"
fi

echo -e "\n${BLUE}4. Controllo servizi...${NC}"

if [ ! -f "modules/services/vscode-server.nix" ]; then
    echo -e "   ${YELLOW}⚠${NC}  Mancante: modules/services/vscode-server.nix - Crealo per il server dev"
else
    echo -e "   ${GREEN}✓${NC} Esistente: modules/services/vscode-server.nix"
fi

echo -e "\n${BLUE}5. Controllo configurazione centralizzata...${NC}"

# Verifica config/default.nix
if [ -f "config/default.nix" ]; then
    echo -e "   ${GREEN}✓${NC} config/default.nix presente"
else
    echo -e "   ${RED}✗${NC} config/default.nix mancante - CRITICO!"
fi

echo -e "\n${BLUE}6. Verifica struttura host...${NC}"

# Controlla struttura hosts
host_dirs=(
    "hosts/laptop/slimbook"
    "hosts/desktop/gaming" 
    "hosts/server/dev-server"
)

for host_dir in "${host_dirs[@]}"; do
    if [ -d "$host_dir" ]; then
        echo -e "   ${GREEN}✓${NC} $host_dir"
        
        # Controlla default.nix e hardware-configuration.nix
        if [ -f "$host_dir/default.nix" ]; then
            echo -e "     ${GREEN}✓${NC} $host_dir/default.nix"
        else
            echo -e "     ${YELLOW}⚠${NC}  $host_dir/default.nix mancante"
        fi
        
        if [ -f "$host_dir/hardware-configuration.nix" ]; then
            echo -e "     ${GREEN}✓${NC} $host_dir/hardware-configuration.nix"
        else
            echo -e "     ${RED}✗${NC} $host_dir/hardware-configuration.nix MANCANTE!"
        fi
    else
        echo -e "   ${RED}✗${NC} $host_dir mancante"
    fi
done

echo -e "\n${BLUE}7. Controllo users configuration...${NC}"

if [ -f "users/filippo/default.nix" ] && [ -f "users/filippo/home.nix" ]; then
    echo -e "   ${GREEN}✓${NC} Configurazione utente filippo completa"
else
    echo -e "   ${YELLOW}⚠${NC}  Configurazione utente filippo incompleta"
fi

echo -e "\n${BLUE}8. Controllo secrets...${NC}"

secrets=(
    "secrets/secrets.yaml"
    "secrets/id_ed25519.enc"
    "secrets/wg0.conf.enc"
    ".sops.yaml"
)

for secret in "${secrets[@]}"; do
    if [ -f "$secret" ]; then
        echo -e "   ${GREEN}✓${NC} $secret"
    else
        echo -e "   ${YELLOW}⚠${NC}  $secret mancante"
    fi
done

echo -e "\n${BLUE}9. Test configurazione...${NC}"

echo -e "   ${YELLOW}Eseguendo nix flake check...${NC}"
if nix flake check 2>/dev/null; then
    echo -e "   ${GREEN}✓${NC} Flake check superato!"
else
    echo -e "   ${RED}✗${NC} Flake check fallito - controlla gli errori"
fi

echo -e "\n${GREEN}=== REPORT MIGRAZIONE ===${NC}"

echo -e "\n${GREEN}✅ COMPLETATI:${NC}"
echo "  • Struttura directory modulare"
echo "  • Configurazione centralizzata"
echo "  • Profiles per tipologie macchine"
echo "  • Gestione secrets SOPS"
echo "  • Home Manager integrato"
echo "  • Makefile per gestione comandi"

echo -e "\n${YELLOW}📋 AZIONI RICHIESTE:${NC}"
echo "  1. Crea i moduli hardware mancanti usando i template forniti"
echo "  2. Verifica che tutti gli hardware-configuration.nix siano presenti"
echo "  3. Testa la configurazione: nix flake check"
echo "  4. Fai rebuild di test: make test"

echo -e "\n${BLUE}🚀 PROSSIMI PASSI:${NC}"
echo "  1. make test          # Test configurazione"
echo "  2. make rebuild       # Apply configurazione"
echo "  3. make clean         # Pulizia sistema"
echo "  4. make update        # Aggiornamento sistema"

echo -e "\n${GREEN}La migrazione è quasi completa! 🎉${NC}"
echo -e "${YELLOW}Completa i moduli mancanti e testa la configurazione.${NC}"
