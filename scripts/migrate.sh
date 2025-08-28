#!/usr/bin/env bash

# Script per riparare la struttura modulare
set -e

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== Riparazione Struttura NixOS ===${NC}"

# Controllo se siamo nella directory corretta
if [ ! -f "flake.nix" ]; then
    echo -e "${RED}Errore: flake.nix non trovato${NC}"
    exit 1
fi

echo -e "${BLUE}1. Rimozione file conflittuali...${NC}"

# Rimuovi i vecchi file che causano conflitti
files_to_remove=(
    "modules/desktop.nix"
    "modules/development.nix" 
    "modules/gaming.nix"
    "modules/server.nix"
    "modules/config/vpn.nix"
)

for file in "${files_to_remove[@]}"; do
    if [ -f "$file" ]; then
        echo -e "   ${YELLOW}Rimuovendo:${NC} $file"
        rm "$file"
    fi
done

echo -e "\n${BLUE}2. Verifica directory necessarie...${NC}"

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

echo -e "\n${BLUE}3. Test configurazione...${NC}"

# Test più dettagliato
echo -e "   ${YELLOW}Eseguendo nix flake check --show-trace...${NC}"
if nix flake check --show-trace 2>&1; then
    echo -e "   ${GREEN}✓${NC} Flake check superato!"
else
    echo -e "   ${RED}✗${NC} Flake check fallito"
    echo -e "\n${YELLOW}Suggerimenti per il debug:${NC}"
    echo -e "  1. Controlla che tutti i moduli importati esistano"
    echo -e "  2. Verifica che non ci siano import circolari"
    echo -e "  3. Usa 'make check' per dettagli completi"
    exit 1
fi

echo -e "\n${GREEN}✅ Struttura riparata con successo!${NC}"
echo -e "\n${BLUE}Prossimi passi:${NC}"
echo -e "  1. ${YELLOW}make test${NC}     - Testa la configurazione"
echo -e "  2. ${YELLOW}make rebuild${NC}  - Applica le modifiche"
