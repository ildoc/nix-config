#!/usr/bin/env bash

# Script completo per riparare la configurazione NixOS
set -e

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== Riparazione Completa NixOS Configuration ===${NC}"

# Controllo se siamo nella directory corretta
if [ ! -f "flake.nix" ]; then
    echo -e "${RED}Errore: flake.nix non trovato${NC}"
    exit 1
fi

echo -e "${BLUE}1. Backup corrente...${NC}"
BACKUP_DIR="../nix-config-backup-$(date +%Y%m%d-%H%M%S)"
cp -r . "$BACKUP_DIR"
echo -e "   ${GREEN}✓${NC} Backup creato in: $BACKUP_DIR"

echo -e "\n${BLUE}2. Rimozione file problematici...${NC}"

# Lista dei file che causano problemi
problematic_files=(
    "modules/desktop.nix"
    "modules/development.nix"
    "modules/gaming.nix" 
    "modules/server.nix"
    "modules/config/vpn.nix"
)

for file in "${problematic_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "   ${YELLOW}Rimuovendo:${NC} $file"
        rm "$file"
    fi
done

echo -e "\n${BLUE}3. Verifica struttura directory...${NC}"

required_dirs=(
    "modules/hardware"
    "modules/desktop"
    "modules/development"
    "modules/gaming"
    "modules/services"
)

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "   ${GREEN}Creata:${NC} $dir"
    fi
done

echo -e "\n${BLUE}4. Verifica file essenziali...${NC}"

essential_files=(
    "modules/core/default.nix"
    "modules/desktop/default.nix"
    "modules/development/default.nix"
    "modules/services/wireguard.nix"
    "config/default.nix"
)

missing_files=()
for file in "${essential_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
        echo -e "   ${RED}✗${NC} Mancante: $file"
    else
        echo -e "   ${GREEN}✓${NC} Presente: $file"
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    echo -e "\n${RED}ERRORE: File essenziali mancanti!${NC}"
    echo -e "Ricrea questi file utilizzando i template forniti:"
    for file in "${missing_files[@]}"; do
        echo -e "  - $file"
    done
    exit 1
fi

echo -e "\n${BLUE}5. Test sintassi flake...${NC}"

if ! nix flake show >/dev/null 2>&1; then
    echo -e "   ${RED}✗${NC} Errore di sintassi nel flake"
    echo -e "   Eseguendo controllo dettagliato..."
    nix flake show --show-trace || true
    exit 1
else
    echo -e "   ${GREEN}✓${NC} Sintassi flake corretta"
fi

echo -e "\n${BLUE}6. Test valutazione configurazione...${NC}"

if nix eval .#nixosConfigurations.slimbook.config.system.name --show-trace >/dev/null 2>&1; then
    echo -e "   ${GREEN}✓${NC} Configurazione valutabile"
else
    echo -e "   ${RED}✗${NC} Errore nella valutazione"
    echo -e "\n${YELLOW}Debug dettagliato:${NC}"
    nix eval .#nixosConfigurations.slimbook.config.system.name --show-trace || true
    exit 1
fi

echo -e "\n${BLUE}7. Test completo flake check...${NC}"

if nix flake check --show-trace >/dev/null 2>&1; then
    echo -e "   ${GREEN}✓${NC} Flake check superato"
else
    echo -e "   ${RED}✗${NC} Flake check fallito"
    echo -e "\n${YELLOW}Output dettagliato:${NC}"
    nix flake check --show-trace || true
    exit 1
fi

echo -e "\n${GREEN}✅ RIPARAZIONE COMPLETATA CON SUCCESSO!${NC}"

echo -e "\n${BLUE}📋 Prossimi passi:${NC}"
echo -e "  1. ${YELLOW}make test${NC}     - Test della configurazione"
echo -e "  2. ${YELLOW}make rebuild${NC}  - Applica le modifiche"
echo -e "  3. ${YELLOW}make clean${NC}    - Pulizia sistema"

echo -e "\n${BLUE}🔧 Comandi di debug utili:${NC}"
echo -e "  • ${YELLOW}nix flake show${NC}                    - Mostra struttura flake"
echo -e "  • ${YELLOW}make check${NC}                        - Verifica configurazione"
echo -e "  • ${YELLOW}nix eval .#nixosConfigurations${NC}    - Valuta host disponibili"
