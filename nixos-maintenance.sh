#!/usr/bin/env bash

# Script di manutenzione NixOS
set -euo pipefail

# Determina la directory dello script (dove si trova il flake.nix reale)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIXOS_CONFIG="$SCRIPT_DIR"
HOSTNAME="${HOSTNAME:-$(hostname)}"

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Flags globali
AUTO_YES=false
VERBOSE=false

# Funzioni helper
log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_header() { echo -e "\n${BOLD}${GREEN}=== $1 ===${NC}\n"; }
log_verbose() { 
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

# Funzione per gestire conferme con supporto -y
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [ "$AUTO_YES" = true ]; then
        log_verbose "Auto-confirm: $prompt (auto-yes enabled)"
        return 0
    fi
    
    local response
    echo -ne "${YELLOW}${prompt} [${default^^}]: ${NC}"
    read -r response
    response="${response:-$default}"
    
    if [[ "${response,,}" == "y" || "${response,,}" == "yes" ]]; then
        return 0
    else
        return 1
    fi
}

# Funzione per prompt con timeout e default con supporto -y
prompt_with_timeout() {
    local prompt="$1"
    local default="$2"
    local timeout="${3:-10}"
    
    if [ "$AUTO_YES" = true ]; then
        log_verbose "Auto-prompt: $prompt (using default: $default)"
        echo "$default"
        return
    fi
    
    local response
    echo -ne "${YELLOW}${prompt} [default: ${default} in ${timeout}s]: ${NC}"
    
    if read -r -t "$timeout" response; then
        response="${response:-$default}"
    else
        echo ""
        log_info "Timeout raggiunto, uso default: ${default}"
        response="$default"
    fi
    
    echo "$response"
}

# Funzione per parsing degli argomenti
parse_args() {
    local command=""
    local remaining_args=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes|--assume-yes)
                AUTO_YES=true
                log_verbose "Auto-yes mode enabled"
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                command="help"
                shift
                ;;
            -*)
                log_error "Opzione non riconosciuta: $1"
                log_info "Usa --help per vedere le opzioni disponibili"
                exit 1
                ;;
            *)
                if [ -z "$command" ]; then
                    command="$1"
                else
                    remaining_args+=("$1")
                fi
                shift
                ;;
        esac
    done
    
    # Se non c'è comando, default a help
    command="${command:-help}"
    
    # Esporta le variabili per l'uso globale
    COMMAND="$command"
    REMAINING_ARGS=("${remaining_args[@]}")
}

# Verifica dipendenze
check_dependencies() {
    local deps=("nix" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Dipendenze mancanti: ${missing[*]}"
        log_info "Installa con: nix-env -iA nixpkgs.${missing[*]}"
        exit 1
    fi
}

# Funzione per formattare bytes
format_bytes() {
    local bytes=$1
    if [ "$bytes" -gt 1073741824 ]; then
        echo "$(( bytes / 1073741824 ))GB"
    elif [ "$bytes" -gt 1048576 ]; then
        echo "$(( bytes / 1048576 ))MB"
    else
        echo "$(( bytes / 1024 ))KB"
    fi
}

# Funzione per calcolare spazio nix store
get_nix_store_size() {
    if [ -d /nix/store ]; then
        du -sb /nix/store 2>/dev/null | cut -f1
    else
        echo 0
    fi
}

# Parse arguments
parse_args "$@"

# Main execution
case "$COMMAND" in
    update)
        log_header "Aggiornamento Sistema NixOS"
        
        if [ "$AUTO_YES" = true ]; then
            log_info "Modalità auto-yes attiva - conferme automatiche"
        fi
        
        cd "$NIXOS_CONFIG"
        
        # Mostra stato git se è un repo
        if [ -d .git ]; then
            if ! git diff --quiet HEAD 2>/dev/null; then
                log_warning "Ci sono modifiche non committate nel repository"
                if ! confirm "Vuoi continuare comunque? (y/N)" "n"; then
                    log_error "Aggiornamento annullato"
                    exit 1
                fi
            fi
        fi
        
        log_info "Aggiornamento flake inputs..."
        if ! nix flake update; then
            log_error "Errore durante l'aggiornamento dei flake inputs"
            exit 1
        fi
        
        # Mostra cosa è stato aggiornato
        if [ -f flake.lock ] && [ -d .git ] && command -v git &>/dev/null; then
            if [ "$VERBOSE" = true ]; then
                echo -e "\n${CYAN}Modifiche ai flake inputs:${NC}"
                git diff flake.lock 2>/dev/null | head -50 || true
            else
                echo -e "\n${CYAN}Modifiche ai flake inputs (sommario):${NC}"
                git diff --stat flake.lock 2>/dev/null || true
            fi
            echo ""
        fi
        
        # Prompt con timeout o auto-yes
        response=$(prompt_with_timeout "Vuoi procedere con il rebuild? (Y/n)" "y" 15)
        
        if [[ "${response,,}" != "n" && "${response,,}" != "no" ]]; then
            log_info "Avvio rebuild del sistema..."
            
            # Dry-build per verificare
            log_info "Verifica configurazione con dry-build..."
            if [ "$VERBOSE" = true ]; then
                echo -e "${CYAN}Output del dry-build:${NC}"
                if ! nixos-rebuild dry-build --flake ".#$HOSTNAME" 2>&1 | tee /tmp/nixos-build.log; then
                    log_error "Dry-build fallito!"
                    exit 1
                fi
            else
                if ! nixos-rebuild dry-build --flake ".#$HOSTNAME" &>/tmp/nixos-build.log 2>&1; then
                    log_error "Dry-build fallito! Usa -v per vedere i dettagli"
                    echo -e "${CYAN}Ultimi errori:${NC}"
                    tail -20 /tmp/nixos-build.log
                    exit 1
                fi
            fi
            
            log_success "Dry-build completato con successo"
            
            # Test build
            if confirm "Vuoi procedere con il test? (Y/n)" "y"; then
                log_info "Test della configurazione..."
                
                if [ "$VERBOSE" = true ]; then
                    echo -e "${CYAN}Output del test:${NC}"
                fi
                
                if sudo nixos-rebuild test --flake ".#$HOSTNAME" 2>&1 | tee -a /tmp/nixos-build.log; then
                    log_success "Test completato con successo"
                    
                    # IMPORTANTE: Switch dopo il test, non boot
                    if confirm "Test riuscito! Applicare permanentemente con switch? (Y/n)" "y"; then
                        log_info "Applicazione permanente della configurazione con switch..."
                        
                        if [ "$VERBOSE" = true ]; then
                            echo -e "${CYAN}Output dello switch:${NC}"
                        fi
                        
                        if sudo nixos-rebuild switch --flake ".#$HOSTNAME" 2>&1 | tee -a /tmp/nixos-build.log; then
                            log_success "Sistema aggiornato con successo!"
                            
                            # Mostra nuova generazione
                            echo ""
                            log_info "Nuova generazione:"
                            sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | tail -1
                            
                            # Pulizia log se tutto ok
                            rm -f /tmp/nixos-build.log
                            
                            log_success "Switch completato - configurazione applicata immediatamente"
                        else
                            log_error "Switch fallito!"
                            exit 1
                        fi
                    else
                        log_warning "Switch annullato - il sistema rimane con il test attivo fino al riavvio"
                    fi
                else
                    log_error "Test fallito!"
                    
                    if confirm "Il test è fallito. Vuoi forzare lo switch? (PERICOLOSO!) (y/N)" "n"; then
                        log_warning "Tentativo di switch forzato..."
                        if sudo nixos-rebuild switch --flake ".#$HOSTNAME" 2>&1 | tee -a /tmp/nixos-build.log; then
                            log_success "Switch forzato riuscito (verificare il sistema!)"
                        else
                            log_error "Anche lo switch forzato è fallito"
                            exit 1
                        fi
                    else
                        log_info "Aggiornamento annullato - sistema non modificato"
                        exit 1
                    fi
                fi
            else
                # Skip test, vai diretto allo switch
                log_info "Skip del test, procedo direttamente con lo switch..."
                if sudo nixos-rebuild switch --flake ".#$HOSTNAME" 2>&1 | tee /tmp/nixos-build.log; then
                    log_success "Sistema aggiornato con successo!"
                    rm -f /tmp/nixos-build.log
                else
                    log_error "Switch fallito!"
                    exit 1
                fi
            fi
        else
            log_warning "Aggiornamento annullato dall'utente"
        fi
        ;;
        
    update-quick|quick-update|quick)
        log_header "Aggiornamento Rapido Sistema NixOS"
        
        if [ "$AUTO_YES" = true ]; then
            log_info "Modalità auto-yes attiva"
        fi
        
        cd "$NIXOS_CONFIG"
        
        log_info "Aggiornamento flake inputs..."
        if ! nix flake update; then
            log_error "Errore durante l'aggiornamento dei flake inputs"
            exit 1
        fi
        
        log_info "Switch diretto del sistema..."
        if sudo nixos-rebuild switch --flake ".#$HOSTNAME" 2>&1 | tee /tmp/nixos-build.log; then
            log_success "Sistema aggiornato con successo!"
            rm -f /tmp/nixos-build.log
        else
            log_error "Switch fallito! Log salvato in: /tmp/nixos-build.log"
            exit 1
        fi
        ;;
        
    clean)
        log_header "Pulizia Sistema NixOS"
        
        # Calcola spazio prima
        size_before=$(get_nix_store_size)
        
        log_info "Spazio occupato: $(format_bytes $size_before)"
        
        # Mostra generazioni che verranno eliminate
        echo -e "\n${CYAN}Generazioni del sistema:${NC}"
        sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | tail -10
        
        if [ "$AUTO_YES" = true ]; then
            # In modalità auto-yes, usa l'opzione sicura (mantieni ultime 3)
            log_info "Auto-yes: mantengo ultime 3 generazioni (opzione sicura)"
            choice=1
        else
            echo -e "\n${YELLOW}Opzioni di pulizia:${NC}"
            echo "  1) Mantieni ultime 3 generazioni (sicuro)"
            echo "  2) Mantieni ultima settimana"
            echo "  3) Mantieni solo generazione corrente (aggressivo)"
            echo "  4) Pulizia personalizzata"
            echo "  0) Annulla"
            
            echo -ne "\n${YELLOW}Scelta [1]: ${NC}"
            read -r choice
            choice=${choice:-1}
        fi
        
        case $choice in
            1)
                log_info "Eliminazione generazioni vecchie (mantieni ultime 3)..."
                sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +3
                ;;
            2)
                log_info "Eliminazione generazioni più vecchie di 7 giorni..."
                sudo nix-collect-garbage --delete-older-than 7d
                ;;
            3)
                log_warning "Eliminazione TUTTE le vecchie generazioni..."
                if confirm "Sei sicuro? Questo eliminerà la possibilità di rollback! (yes/NO)" "no"; then
                    sudo nix-collect-garbage -d
                else
                    log_info "Operazione annullata"
                    exit 0
                fi
                ;;
            4)
                echo -ne "${YELLOW}Mantieni ultime N generazioni: ${NC}"
                read -r n
                if [[ "$n" =~ ^[0-9]+$ ]]; then
                    sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +$n
                else
                    log_error "Numero non valido"
                    exit 1
                fi
                ;;
            0|*)
                log_info "Pulizia annullata"
                exit 0
                ;;
        esac
        
        # Garbage collection
        log_info "Esecuzione garbage collection..."
        sudo nix-collect-garbage
        
        # Ottimizza store
        log_info "Ottimizzazione store Nix (deduplicazione)..."
        sudo nix-store --optimise
        
        # Calcola spazio dopo
        size_after=$(get_nix_store_size)
        saved=$((size_before - size_after))
        
        echo ""
        log_success "Pulizia completata!"
        log_info "Spazio prima: $(format_bytes $size_before)"
        log_info "Spazio dopo:  $(format_bytes $size_after)"
        log_success "Spazio liberato: $(format_bytes $saved)"
        ;;
        
    check|status)
        log_header "Stato Sistema NixOS"
        
        # Info sistema
        echo -e "${CYAN}Sistema:${NC}"
        echo "  Hostname:    $HOSTNAME"
        echo "  NixOS:       $(nixos-version)"
        echo "  Kernel:      $(uname -r)"
        echo "  Architettura: $(uname -m)"
        
        # Info generazioni
        echo -e "\n${CYAN}Generazioni:${NC}"
        current_gen=$(sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | grep "(current)" | awk '{print $1}')
        total_gens=$(sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | wc -l)
        echo "  Corrente:    #$current_gen"
        echo "  Totali:      $total_gens"
        
        echo -e "\n${CYAN}Ultime 5 generazioni:${NC}"
        sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | tail -5 | sed 's/^/  /'
        
        # Info storage
        echo -e "\n${CYAN}Storage:${NC}"
        store_size=$(get_nix_store_size)
        echo "  Nix Store:   $(format_bytes $store_size)"
        echo "  Disco root:  $(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 " usato)"}')"
        
        # Info flake
        if [ -f "$NIXOS_CONFIG/flake.nix" ]; then
            echo -e "\n${CYAN}Flake inputs:${NC}"
            cd "$NIXOS_CONFIG"
            nix flake metadata --json 2>/dev/null | \
                jq -r '.locks.nodes | to_entries[] | select(.key != "root") | "  \(.key): \(.value.locked.rev[:12] // "unknown")"' | \
                head -10
        fi
        
        # Suggerimenti
        echo -e "\n${CYAN}Comandi utili:${NC}"
        echo "  $0 update-check  - Controlla aggiornamenti disponibili"
        echo "  $0 diff          - Mostra differenze con ultima build"
        echo "  $0 clean         - Libera spazio disco"
        ;;
        
    update-check)
        log_header "Controllo Aggiornamenti"
        
        cd "$NIXOS_CONFIG"
        
        log_info "Recupero informazioni attuali..."
        current_metadata=$(nix flake metadata --json 2>/dev/null)
        
        # Crea copia temporanea per test
        tmp_dir=$(mktemp -d)
        trap "rm -rf $tmp_dir" EXIT
        
        cp flake.* "$tmp_dir/" 2>/dev/null || {
            log_error "Nessun flake trovato in $NIXOS_CONFIG"
            exit 1
        }
        
        cd "$tmp_dir"
        
        log_info "Controllo aggiornamenti disponibili..."
        nix flake update --no-registries &>/dev/null
        
        updated_metadata=$(nix flake metadata --json 2>/dev/null)
        
        # Confronta inputs
        updates_found=false
        
        for input in $(echo "$current_metadata" | jq -r '.locks.nodes | keys[]' | grep -v "^root$"); do
            current_rev=$(echo "$current_metadata" | jq -r ".locks.nodes[\"$input\"].locked.rev // \"N/A\"" 2>/dev/null | cut -c1-12)
            updated_rev=$(echo "$updated_metadata" | jq -r ".locks.nodes[\"$input\"].locked.rev // \"N/A\"" 2>/dev/null | cut -c1-12)
            
            if [ "$current_rev" != "$updated_rev" ] && [ "$current_rev" != "N/A" ]; then
                if [ "$updates_found" = false ]; then
                    echo -e "\n${GREEN}Aggiornamenti disponibili:${NC}\n"
                    updates_found=true
                fi
                
                # Date
                current_date=$(echo "$current_metadata" | jq -r ".locks.nodes[\"$input\"].locked.lastModified // 0")
                updated_date=$(echo "$updated_metadata" | jq -r ".locks.nodes[\"$input\"].locked.lastModified // 0")
                
                # Formatta date
                if [ "$current_date" -ne 0 ]; then
                    current_date_str=$(date -d "@$current_date" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")
                    updated_date_str=$(date -d "@$updated_date" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")
                    days_diff=$(( ($updated_date - $current_date) / 86400 ))
                    
                    echo -e "${BLUE}$input${NC}:"
                    echo -e "  Attuale:     $current_rev ($current_date_str)"
                    echo -e "  Disponibile: ${GREEN}$updated_rev${NC} ($updated_date_str)"
                    echo -e "  Differenza:  ${YELLOW}${days_diff} giorni${NC}"
                    echo ""
                fi
            fi
        done
        
        if [ "$updates_found" = true ]; then
            log_info "Usa '$0 update' per applicare gli aggiornamenti"
        else
            log_success "Tutti i pacchetti sono aggiornati!"
        fi
        ;;
        
    rollback)
        log_header "Rollback Sistema"
        
        current_gen=$(sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | grep "(current)" | awk '{print $1}')
        
        echo -e "${CYAN}Generazioni disponibili:${NC}"
        sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | tail -10
        
        if [ "$AUTO_YES" = true ]; then
            target_gen=$(($current_gen - 1))
            log_info "Auto-yes: rollback alla generazione precedente (#$target_gen)"
        else
            echo -e "\n${YELLOW}A quale generazione vuoi tornare? (default: precedente)${NC}"
            echo -ne "Numero generazione [$(($current_gen - 1))]: "
            read -r target_gen
            target_gen=${target_gen:-$(($current_gen - 1))}
        fi
        
        if [[ ! "$target_gen" =~ ^[0-9]+$ ]]; then
            log_error "Numero generazione non valido"
            exit 1
        fi
        
        if [ "$target_gen" -ge "$current_gen" ]; then
            log_error "La generazione target deve essere precedente a quella corrente ($current_gen)"
            exit 1
        fi
        
        log_warning "Rollback da generazione #$current_gen a #$target_gen"
        
        if confirm "Procedere? (y/N)" "n"; then
            if sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation "$target_gen"; then
                log_success "Rollback completato!"
                log_info "Riavvia il sistema per applicare completamente le modifiche"
            else
                log_error "Rollback fallito"
                exit 1
            fi
        else
            log_info "Rollback annullato"
        fi
        ;;
        
    test)
        log_header "Test Configurazione"
        
        cd "$NIXOS_CONFIG"
        log_info "Build e test della configurazione (non permanente)..."
        
        if sudo nixos-rebuild test --flake ".#$HOSTNAME" 2>&1 | tee /tmp/nixos-test.log; then
            log_success "Test completato con successo!"
            log_info "La configurazione è attiva fino al prossimo riavvio"
            rm -f /tmp/nixos-test.log
        else
            log_error "Test fallito"
            log_info "Log salvato in: /tmp/nixos-test.log"
            exit 1
        fi
        ;;
        
    switch)
        log_header "Switch Configurazione"
        
        cd "$NIXOS_CONFIG"
        
        if confirm "Applicare la configurazione con switch? (y/N)" "n"; then
            log_info "Switch della configurazione..."
            
            if sudo nixos-rebuild switch --flake ".#$HOSTNAME" 2>&1 | tee /tmp/nixos-switch.log; then
                log_success "Switch completato con successo!"
                log_info "La configurazione è stata applicata immediatamente"
                rm -f /tmp/nixos-switch.log
            else
                log_error "Switch fallito"
                log_info "Log salvato in: /tmp/nixos-switch.log"
                exit 1
            fi
        else
            log_info "Switch annullato"
        fi
        ;;
        
    boot)
        log_header "Boot Configurazione"
        
        cd "$NIXOS_CONFIG"
        
        if confirm "Impostare la configurazione per il prossimo boot? (y/N)" "n"; then
            log_info "Impostazione configurazione per il boot..."
            
            if sudo nixos-rebuild boot --flake ".#$HOSTNAME" 2>&1 | tee /tmp/nixos-boot.log; then
                log_success "Configurazione impostata per il prossimo boot!"
                log_info "La configurazione sarà attiva dopo il riavvio"
                rm -f /tmp/nixos-boot.log
            else
                log_error "Boot setup fallito"
                log_info "Log salvato in: /tmp/nixos-boot.log"
                exit 1
            fi
        else
            log_info "Boot setup annullato"
        fi
        ;;
        
    build|dry-build)
        log_header "Build Configurazione"
        
        cd "$NIXOS_CONFIG"
        log_info "Build della configurazione senza applicare..."
        
        if nixos-rebuild build --flake ".#$HOSTNAME" 2>&1 | tee /tmp/nixos-build.log; then
            log_success "Build completata!"
            log_info "Il risultato è in: ./result"
            
            # Mostra info sulla build
            if [ -L ./result ]; then
                echo -e "\n${CYAN}Informazioni build:${NC}"
                echo "  Path:     $(readlink ./result)"
                echo "  Versione: $(./result/sw/bin/nixos-version 2>/dev/null || echo "N/A")"
            fi
            rm -f /tmp/nixos-build.log
        else
            log_error "Build fallita"
            log_info "Log salvato in: /tmp/nixos-build.log"
            exit 1
        fi
        ;;
        
    diff)
        log_header "Differenze Configurazione"
        
        cd "$NIXOS_CONFIG"
        log_info "Build della nuova configurazione..."
        
        if nixos-rebuild build --flake ".#$HOSTNAME" &>/dev/null; then
            log_info "Calcolo differenze tra sistema attuale e nuova build..."
            echo ""
            
            # Usa nix store diff-closures per mostrare le differenze
            nix store diff-closures /run/current-system ./result | head -50
            
            # Mostra statistiche
            echo -e "\n${CYAN}Statistiche:${NC}"
            total_changes=$(nix store diff-closures /run/current-system ./result 2>/dev/null | wc -l)
            echo "  Totale cambiamenti: $total_changes"
            
            if [ "$total_changes" -eq 0 ]; then
                log_success "Nessuna differenza - il sistema è già aggiornato"
            fi
        else
            log_error "Build fallita"
            exit 1
        fi
        ;;
        
    changelog)
        log_header "Changelog NixOS"
        
        cd "$NIXOS_CONFIG"
        
        # Determina il branch da controllare
        nixpkgs_url=$(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes.nixpkgs.locked.url // ""')
        
        if [[ "$nixpkgs_url" == *"nixos-"* ]]; then
            branch=$(echo "$nixpkgs_url" | grep -oP 'nixos-\d+\.\d+' | head -1)
        else
            branch="nixos-unstable"
        fi
        
        log_info "Recupero changelog per branch: $branch"
        
        # API GitHub per i commit
        api_url="https://api.github.com/repos/NixOS/nixpkgs/commits?sha=${branch}&per_page=30"
        
        echo -e "\n${CYAN}Ultimi commit significativi:${NC}\n"
        
        if curl -s "$api_url" | jq -r '.[] | "• [\(.sha[0:7])] \(.commit.message | split("\n")[0]) - \(.commit.author.name) (\(.commit.author.date | split("T")[0]))"' 2>/dev/null | head -20; then
            echo -e "\n${BLUE}Link utili:${NC}"
            echo "  Changelog completo: https://github.com/NixOS/nixpkgs/commits/$branch"
            echo "  Pull requests:      https://github.com/NixOS/nixpkgs/pulls"
        else
            log_warning "Impossibile recuperare il changelog. Controlla la connessione internet."
        fi
        ;;
        
    repair)
        log_header "Riparazione Store Nix"
        
        if confirm "Questa operazione verificherà e riparerà lo store Nix. Procedere? (y/N)" "n"; then
            log_info "Verifica integrità store..."
            sudo nix-store --verify --check-contents
            
            log_info "Riparazione percorsi danneggiati..."
            sudo nix-store --repair --verify
            
            log_success "Riparazione completata!"
        else
            log_info "Riparazione annullata"
        fi
        ;;
        
    help|--help|-h|*)
        echo -e "${BOLD}${GREEN}NixOS Maintenance Script${NC}"
        echo -e "${CYAN}Gestione semplificata del sistema NixOS${NC}\n"
        
        echo -e "${BOLD}USO:${NC}"
        echo -e "  $0 [OPZIONI] COMANDO [ARGOMENTI]"
        echo ""
        
        echo -e "${
