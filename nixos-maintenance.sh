#!/usr/bin/env bash

# Script di manutenzione NixOS
set -e

# Determina la directory dello script (dove si trova il flake.nix reale)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIXOS_CONFIG="$SCRIPT_DIR"
HOSTNAME=$(hostname)

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== NixOS Maintenance Script ===${NC}"
echo -e "${BLUE}Config dir: $NIXOS_CONFIG${NC}"

case "$1" in
    update)
        echo -e "${YELLOW}Aggiornamento flake inputs...${NC}"
        cd "$NIXOS_CONFIG"
        nix flake update
        
        echo -e "${YELLOW}Vuoi procedere con l'aggiornamento? (y/n)${NC}"
        read -r response
        if [[ "$response" == "y" ]]; then
            sudo nixos-rebuild switch --flake ".#$HOSTNAME"
        fi
        ;;
        
    clean)
        echo -e "${YELLOW}Pulizia sistema...${NC}"
        
        # Mostra spazio prima
        echo "Spazio occupato prima: $(du -sh /nix/store 2>/dev/null | cut -f1)"
        
        # Mostra generazioni che verranno eliminate
        echo -e "\nGenerazioni che verranno eliminate:"
        sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | head -n -3
        
        echo -e "\n${YELLOW}Procedere? (y/n)${NC}"
        read -r response
        if [[ "$response" == "y" ]]; then
            # Mantieni solo le ultime 3 generazioni
            sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +3
            
            # Garbage collection
            sudo nix-collect-garbage -d
            
            # Ottimizza store
            echo -e "${YELLOW}Ottimizzazione store Nix...${NC}"
            sudo nix-store --optimise
        fi
        
        # Mostra spazio dopo
        echo "Spazio occupato dopo: $(du -sh /nix/store 2>/dev/null | cut -f1)"
        ;;
        
    check)
        echo -e "${YELLOW}Controllo sistema...${NC}"
        echo "Generazione corrente:"
        nixos-version
        
        echo -e "\nUltime 5 generazioni:"
        sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | tail -5
        
        echo -e "\nSpazio disco Nix:"
        du -sh /nix/store 2>/dev/null || echo "Impossibile calcolare"
        
        echo -e "\nFlake inputs:"
        cd "$NIXOS_CONFIG"
        nix flake metadata --json | jq -r '.locks.nodes | to_entries[] | select(.key != "root") | "\(.key): \(.value.locked.rev // .value.locked.narHash // "unknown")"' | head -10
        
        echo -e "\n${YELLOW}Per vedere gli aggiornamenti disponibili, usa:${NC}"
        echo "  $0 update-check"
        ;;
        
    update-check)
        echo -e "${YELLOW}Controllo aggiornamenti disponibili...${NC}"
        cd "$NIXOS_CONFIG"
        
        # Salva metadata corrente
        echo "Recupero informazioni attuali..."
        current_metadata=$(nix flake metadata --json)
        
        # Crea un file temporaneo per il flake aggiornato
        tmp_dir=$(mktemp -d)
        cp flake.* "$tmp_dir/"
        cd "$tmp_dir"
        
        echo "Controllo ultimi aggiornamenti..."
        nix flake update --no-registries 2>/dev/null
        
        # Ottieni metadata aggiornato
        updated_metadata=$(nix flake metadata --json)
        
        echo -e "\n${GREEN}=== Aggiornamenti Disponibili ===${NC}\n"
        
        # Confronta ogni input
        for input in $(echo "$current_metadata" | jq -r '.locks.nodes | keys[]' | grep -v "^root$"); do
            current_rev=$(echo "$current_metadata" | jq -r ".locks.nodes[\"$input\"].locked.rev // \"N/A\"" | cut -c1-12)
            updated_rev=$(echo "$updated_metadata" | jq -r ".locks.nodes[\"$input\"].locked.rev // \"N/A\"" | cut -c1-12)
            
            if [ "$current_rev" != "$updated_rev" ] && [ "$current_rev" != "N/A" ]; then
                # Ottieni date
                current_date=$(echo "$current_metadata" | jq -r ".locks.nodes[\"$input\"].locked.lastModified // 0")
                updated_date=$(echo "$updated_metadata" | jq -r ".locks.nodes[\"$input\"].locked.lastModified // 0")
                
                # Converti timestamp in date leggibili
                if command -v date >/dev/null 2>&1; then
                    current_date_str=$(date -d "@$current_date" "+%Y-%m-%d" 2>/dev/null || echo "Unknown")
                    updated_date_str=$(date -d "@$updated_date" "+%Y-%m-%d" 2>/dev/null || echo "Unknown")
                else
                    current_date_str="timestamp:$current_date"
                    updated_date_str="timestamp:$updated_date"
                fi
                
                # Calcola giorni di differenza
                if [ "$current_date" -ne 0 ] && [ "$updated_date" -ne 0 ]; then
                    days_diff=$(( ($updated_date - $current_date) / 86400 ))
                    days_info=" (${days_diff} giorni)"
                else
                    days_info=""
                fi
                
                echo -e "${BLUE}$input${NC}:"
                echo -e "  Attuale:    $current_rev ($current_date_str)"
                echo -e "  Disponibile: ${GREEN}$updated_rev${NC} ($updated_date_str)$days_info"
                
                # Per nixpkgs, mostra anche la versione
                if [[ "$input" == *"nixpkgs"* ]]; then
                    # Prova a ottenere info sulla versione
                    cd "$NIXOS_CONFIG"
                    current_version=$(nix eval --raw ".#$input.lib.version" 2>/dev/null || echo "")
                    cd "$tmp_dir"
                    updated_version=$(nix eval --raw ".#$input.lib.version" 2>/dev/null || echo "")
                    
                    if [ -n "$current_version" ] && [ -n "$updated_version" ] && [ "$current_version" != "$updated_version" ]; then
                        echo -e "  Versione:    $current_version → ${GREEN}$updated_version${NC}"
                    fi
                fi
                echo ""
            fi
        done
        
        # Se nessun aggiornamento trovato
        if ! echo "$updated_metadata" | jq -r '.locks.nodes' | diff -q <(echo "$current_metadata" | jq -r '.locks.nodes') - >/dev/null 2>&1; then
            echo -e "${YELLOW}Suggerimento:${NC} Usa '$0 update' per applicare questi aggiornamenti"
        else
            echo -e "${GREEN}✓${NC} Tutti i pacchetti sono aggiornati!"
        fi
        
        # Pulizia
        rm -rf "$tmp_dir"
        ;;
        
    rollback)
        echo -e "${YELLOW}Rollback alla generazione precedente...${NC}"
        current_gen=$(sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | grep "(current)" | awk '{print $1}')
        prev_gen=$((current_gen - 1))
        
        echo "Generazione corrente: $current_gen"
        echo "Rollback a generazione: $prev_gen"
        echo -e "${YELLOW}Procedere? (y/n)${NC}"
        read -r response
        if [[ "$response" == "y" ]]; then
            sudo nixos-rebuild switch --rollback
        fi
        ;;
        
    test)
        echo -e "${YELLOW}Test configurazione...${NC}"
        cd "$NIXOS_CONFIG"
        sudo nixos-rebuild test --flake ".#$HOSTNAME"
        ;;
        
    build)
        echo -e "${YELLOW}Build configurazione senza applicare...${NC}"
        cd "$NIXOS_CONFIG"
        nixos-rebuild build --flake ".#$HOSTNAME"
        echo -e "${GREEN}Build completata. Il risultato è in ./result${NC}"
        ;;
        
    diff)
        echo -e "${YELLOW}Differenze tra generazione corrente e build...${NC}"
        cd "$NIXOS_CONFIG"
        nixos-rebuild build --flake ".#$HOSTNAME" 2>/dev/null
        nix store diff-closures /run/current-system ./result
        ;;
        
    changelog)
        echo -e "${YELLOW}Recupero changelog nixpkgs...${NC}"
        cd "$NIXOS_CONFIG"
        
        # Ottieni i commit di nixpkgs
        current_rev=$(nix flake metadata --json | jq -r '.locks.nodes.nixpkgs.locked.rev' | cut -c1-12)
        
        echo -e "\n${GREEN}Changelog recenti per nixpkgs (dal commit $current_rev):${NC}\n"
        
        # Mostra gli ultimi commit significativi
        echo "Recupero informazioni da GitHub..."
        curl -s "https://api.github.com/repos/NixOS/nixpkgs/commits?sha=nixos-25.05&per_page=20" | \
            jq -r '.[] | "• \(.sha[0:7]) - \(.commit.message | split("\n")[0]) (\(.commit.author.date | split("T")[0]))"' | \
            head -15
        
        echo -e "\n${BLUE}Per vedere il changelog completo:${NC}"
        echo "  https://github.com/NixOS/nixpkgs/commits/nixos-25.05"
        ;;
        
    *)
        echo "Uso: $0 {update|clean|check|update-check|changelog|rollback|test|build|diff}"
        echo ""
        echo "  update        - Aggiorna flake e ricostruisci sistema"
        echo "  clean         - Pulisci generazioni vecchie e ottimizza"
        echo "  check         - Mostra informazioni sul sistema"
        echo "  update-check  - Controlla aggiornamenti disponibili (dettagliato)"
        echo "  changelog     - Mostra changelog recenti di nixpkgs"
        echo "  rollback      - Torna alla generazione precedente"
        echo "  test          - Testa la configurazione (temporanea)"
        echo "  build         - Costruisci senza applicare"
        echo "  diff          - Mostra differenze tra sistema attuale e build"
        exit 1
        ;;
esac
