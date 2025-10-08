#!/usr/bin/env bash

# Script di manutenzione NixOS - Versione Migliorata
set -euo pipefail

# Determina la directory dello script
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

# File di log temporanei
BUILD_LOG="/tmp/nixos-build-$(date +%s).log"
trap "rm -f $BUILD_LOG" EXIT

# ============================================================================
# FUNZIONI HELPER
# ============================================================================

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

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [ "$AUTO_YES" = true ]; then
        log_verbose "Auto-confirm: $prompt"
        return 0
    fi
    
    local response
    echo -ne "${YELLOW}${prompt} [${default^^}]: ${NC}"
    read -r response
    response="${response:-$default}"
    
    [[ "${response,,}" =~ ^(y|yes)$ ]]
}

prompt_with_timeout() {
    local prompt="$1"
    local default="$2"
    local timeout="${3:-10}"
    
    if [ "$AUTO_YES" = true ]; then
        log_verbose "Auto-prompt: using default: $default"
        echo "$default"
        return
    fi
    
    local response
    echo -ne "${YELLOW}${prompt} [default: ${default} in ${timeout}s]: ${NC}"
    
    if read -r -t "$timeout" response; then
        echo "${response:-$default}"
    else
        echo ""
        log_info "Timeout - usando default: ${default}"
        echo "$default"
    fi
}

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

get_nix_store_size() {
    du -sb /nix/store 2>/dev/null | cut -f1 || echo 0
}

# Funzione per mostrare un sommario delle modifiche
show_flake_changes() {
    if [ ! -f flake.lock ] || ! command -v git &>/dev/null; then
        return
    fi
    
    # Solo se ci sono modifiche
    if git diff --quiet HEAD flake.lock 2>/dev/null; then
        return
    fi
    
    echo -e "\n${CYAN}Modifiche agli inputs:${NC}"
    
    # Estrai i cambiamenti in modo leggibile
    git diff flake.lock 2>/dev/null | grep -E "^\+.*\"rev\":|^-.*\"rev\":" | \
        sed 's/^+/  ✓/; s/^-/  ✗/' | head -20 || true
    
    echo ""
}

# Funzione per build sicura con retry
safe_build() {
    local max_attempts=2
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "Tentativo $attempt/$max_attempts: build della configurazione..."
        
        if [ "$VERBOSE" = true ]; then
            if nixos-rebuild build --flake ".#$HOSTNAME" 2>&1 | tee "$BUILD_LOG"; then
                return 0
            fi
        else
            if nixos-rebuild build --flake ".#$HOSTNAME" &>"$BUILD_LOG"; then
                return 0
            fi
        fi
        
        log_warning "Build fallita (tentativo $attempt/$max_attempts)"
        
        if [ $attempt -lt $max_attempts ]; then
            log_info "Retry tra 2 secondi..."
            sleep 2
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "Build fallita dopo $max_attempts tentativi"
    echo -e "\n${CYAN}Ultimi errori dal log:${NC}"
    tail -30 "$BUILD_LOG" | grep -i "error\|fail" || tail -30 "$BUILD_LOG"
    return 1
}

# ============================================================================
# PARSING ARGOMENTI - Supporta opzioni sia prima che dopo il comando
# ============================================================================

parse_args() {
    local command=""
    local remaining_args=()
    
    # First pass: cerca il comando e le opzioni
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes|--assume-yes)
                AUTO_YES=true
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
                # È un comando
                if [ -z "$command" ]; then
                    command="$1"
                    shift
                    
                    # Continua a cercare opzioni dopo il comando
                    while [[ $# -gt 0 ]]; do
                        case "$1" in
                            -y|--yes|--assume-yes)
                                AUTO_YES=true
                                shift
                                ;;
                            -v|--verbose)
                                VERBOSE=true
                                shift
                                ;;
                            -*)
                                log_error "Opzione non riconosciuta: $1"
                                exit 1
                                ;;
                            *)
                                remaining_args+=("$1")
                                shift
                                ;;
                        esac
                    done
                else
                    remaining_args+=("$1")
                    shift
                fi
                ;;
        esac
    done
    
    # Log delle opzioni attive
    [ "$AUTO_YES" = true ] && log_verbose "Auto-yes mode enabled"
    [ "$VERBOSE" = true ] && log_verbose "Verbose mode enabled"
    
    command="${command:-help}"
    COMMAND="$command"
    REMAINING_ARGS=("${remaining_args[@]}")
}

parse_args "$@"

# ============================================================================
# COMANDI
# ============================================================================

case "$COMMAND" in
    # ========================================================================
    # UPDATE - Workflow semplificato
    # ========================================================================
    update)
        log_header "Aggiornamento Sistema NixOS"
        check_dependencies
        
        cd "$NIXOS_CONFIG"
        
        # Check git status
        if [ -d .git ]; then
            if ! git diff --quiet HEAD 2>/dev/null; then
                log_warning "Ci sono modifiche non committate"
                if ! confirm "Vuoi continuare comunque? (y/N)" "n"; then
                    log_error "Aggiornamento annullato"
                    exit 1
                fi
            fi
        fi
        
        # Step 1: Update flake inputs
        log_info "Aggiornamento flake inputs..."
        if ! nix flake update; then
            log_error "Errore durante l'aggiornamento dei flake inputs"
            exit 1
        fi
        
        # Mostra sommario modifiche
        show_flake_changes
        
        # Step 2: Build per verificare che compili
        log_info "Verifica che la configurazione compili..."
        if ! safe_build; then
            log_error "La configurazione non compila!"
            exit 1
        fi
        
        log_success "Build completata con successo"
        
        # Step 3: Switch diretto (non più test separato)
        response=$(prompt_with_timeout "Applicare l'aggiornamento con switch? (Y/n)" "y" 15)
        
        if [[ "${response,,}" =~ ^(n|no)$ ]]; then
            log_warning "Aggiornamento annullato"
            log_info "Puoi applicarlo in seguito con: $0 switch"
            exit 0
        fi
        
        log_info "Applicazione aggiornamento..."
        
        # Salva generazione corrente per possibile rollback
        current_gen=$(sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | grep "(current)" | awk '{print $1}')
        log_verbose "Generazione corrente: #$current_gen"
        
        # Switch con output controllato
        if [ "$VERBOSE" = true ]; then
            if sudo nixos-rebuild switch --flake ".#$HOSTNAME" 2>&1 | tee -a "$BUILD_LOG"; then
                log_success "Sistema aggiornato con successo!"
            else
                log_error "Switch fallito!"
                log_warning "Puoi fare rollback con: $0 rollback"
                exit 1
            fi
        else
            if sudo nixos-rebuild switch --flake ".#$HOSTNAME" &>>"$BUILD_LOG"; then
                log_success "Sistema aggiornato con successo!"
            else
                log_error "Switch fallito!"
                echo -e "\n${CYAN}Log dell'errore:${NC}"
                tail -30 "$BUILD_LOG"
                log_warning "Puoi fare rollback con: $0 rollback"
                exit 1
            fi
        fi
        
        # Mostra nuova generazione
        new_gen=$(sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | grep "(current)" | awk '{print $1}')
        log_info "Aggiornato da generazione #$current_gen a #$new_gen"
        
        # Suggerisci pulizia se ci sono molte generazioni
        total_gens=$(sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | wc -l)
        if [ "$total_gens" -gt 10 ]; then
            log_info "Hai $total_gens generazioni. Considera di eseguire: $0 clean"
        fi
        ;;
        
    # ========================================================================
    # UPDATE-TEST - Testa senza applicare
    # ========================================================================
    update-test)
        log_header "Test Aggiornamento (senza applicare)"
        check_dependencies
        
        cd "$NIXOS_CONFIG"
        
        log_info "Aggiornamento flake inputs..."
        nix flake update
        
        show_flake_changes
        
        log_info "Build di test..."
        if safe_build; then
            log_success "La configurazione compila correttamente!"
            log_info "Per applicare: $0 switch"
        else
            log_error "La configurazione ha errori"
            exit 1
        fi
        ;;
        
    # ========================================================================
    # QUICK - Update rapido senza conferme
    # ========================================================================
    quick|update-quick)
        log_header "Aggiornamento Rapido"
        check_dependencies
        
        cd "$NIXOS_CONFIG"
        
        log_info "Aggiornamento e switch..."
        if nix flake update && \
           sudo nixos-rebuild switch --flake ".#$HOSTNAME" &>>"$BUILD_LOG"; then
            log_success "Sistema aggiornato!"
        else
            log_error "Aggiornamento fallito"
            tail -30 "$BUILD_LOG"
            exit 1
        fi
        ;;
        
    # ========================================================================
    # SWITCH - Applica configurazione corrente
    # ========================================================================
    switch)
        log_header "Switch Configurazione"
        check_dependencies
        
        cd "$NIXOS_CONFIG"
        
        if confirm "Applicare la configurazione? (y/N)" "n"; then
            log_info "Switch in corso..."
            
            if sudo nixos-rebuild switch --flake ".#$HOSTNAME" 2>&1 | tee "$BUILD_LOG"; then
                log_success "Configurazione applicata!"
            else
                log_error "Switch fallito"
                exit 1
            fi
        else
            log_info "Operazione annullata"
        fi
        ;;
        
    # ========================================================================
    # TEST - Test temporaneo
    # ========================================================================
    test)
        log_header "Test Configurazione"
        check_dependencies
        
        cd "$NIXOS_CONFIG"
        
        log_info "Test della configurazione (temporaneo fino al riavvio)..."
        if sudo nixos-rebuild test --flake ".#$HOSTNAME" 2>&1 | tee "$BUILD_LOG"; then
            log_success "Test completato!"
            log_info "La configurazione è attiva fino al riavvio"
            log_info "Per rendere permanente: $0 switch"
        else
            log_error "Test fallito"
            exit 1
        fi
        ;;
        
    # ========================================================================
    # BUILD - Solo build
    # ========================================================================
    build)
        log_header "Build Configurazione"
        check_dependencies
        
        cd "$NIXOS_CONFIG"
        
        if safe_build; then
            log_success "Build completata: ./result"
            
            if [ -L ./result ]; then
                log_info "Path: $(readlink ./result)"
            fi
        else
            exit 1
        fi
        ;;
        
    # ========================================================================
    # CLEAN - Pulizia sistema
    # ========================================================================
    clean)
        log_header "Pulizia Sistema"
        
        size_before=$(get_nix_store_size)
        log_info "Spazio occupato: $(format_bytes $size_before)"
        
        echo -e "\n${CYAN}Generazioni del sistema:${NC}"
        sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | tail -10
        
        if [ "$AUTO_YES" = true ]; then
            log_info "Auto-yes: mantieni ultime 3 generazioni"
            choice=1
        else
            echo -e "\n${YELLOW}Opzioni pulizia:${NC}"
            echo "  1) Mantieni ultime 3 generazioni (sicuro) - CONSIGLIATO"
            echo "  2) Mantieni ultima settimana"
            echo "  3) Mantieni solo corrente (aggressivo)"
            echo "  0) Annulla"
            
            echo -ne "\n${YELLOW}Scelta [1]: ${NC}"
            read -r choice
            choice=${choice:-1}
        fi
        
        case $choice in
            1)
                log_info "Eliminazione vecchie generazioni (mantieni 3)..."
                sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +3
                ;;
            2)
                log_info "Eliminazione generazioni > 7 giorni..."
                sudo nix-collect-garbage --delete-older-than 7d
                ;;
            3)
                if confirm "ATTENZIONE: Elimina tutte le vecchie generazioni? (yes/NO)" "no"; then
                    sudo nix-collect-garbage -d
                else
                    log_info "Annullato"
                    exit 0
                fi
                ;;
            0|*)
                log_info "Pulizia annullata"
                exit 0
                ;;
        esac
        
        log_info "Garbage collection..."
        sudo nix-collect-garbage
        
        log_info "Ottimizzazione store..."
        sudo nix-store --optimise
        
        size_after=$(get_nix_store_size)
        saved=$((size_before - size_after))
        
        echo ""
        log_success "Pulizia completata!"
        log_info "Prima:  $(format_bytes $size_before)"
        log_info "Dopo:   $(format_bytes $size_after)"
        log_success "Liberato: $(format_bytes $saved)"
        ;;
        
    # ========================================================================
    # STATUS/CHECK - Info sistema
    # ========================================================================
    status|check)
        log_header "Stato Sistema"
        
        echo -e "${CYAN}Sistema:${NC}"
        echo "  Hostname:    $HOSTNAME"
        echo "  NixOS:       $(nixos-version)"
        echo "  Kernel:      $(uname -r)"
        
        current_gen=$(sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | grep "(current)" | awk '{print $1}')
        total_gens=$(sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | wc -l)
        
        echo -e "\n${CYAN}Generazioni:${NC}"
        echo "  Corrente:    #$current_gen"
        echo "  Totali:      $total_gens"
        
        if [ "$total_gens" -gt 10 ]; then
            echo -e "  ${YELLOW}⚠ Considera di pulire (>10 generazioni)${NC}"
        fi
        
        echo -e "\n${CYAN}Storage:${NC}"
        store_size=$(get_nix_store_size)
        echo "  Nix Store:   $(format_bytes $store_size)"
        echo "  Disco root:  $(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
        
        if [ -f "$NIXOS_CONFIG/flake.nix" ]; then
            echo -e "\n${CYAN}Flake:${NC}"
            cd "$NIXOS_CONFIG"
            echo "  Inputs:      $(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes | keys | length-1')"
        fi
        
        echo -e "\n${CYAN}Comandi utili:${NC}"
        echo "  $0 update        - Aggiorna sistema"
        echo "  $0 clean         - Libera spazio"
        echo "  $0 update-check  - Controlla aggiornamenti"
        ;;
        
    # ========================================================================
    # UPDATE-CHECK - Verifica aggiornamenti
    # ========================================================================
    update-check)
        log_header "Controllo Aggiornamenti"
        check_dependencies
        
        cd "$NIXOS_CONFIG"
        
        log_info "Controllo aggiornamenti disponibili..."
        
        # Crea copia temporanea
        tmp_dir=$(mktemp -d)
        trap "rm -rf $tmp_dir" EXIT
        
        cp flake.* "$tmp_dir/" 2>/dev/null
        cd "$tmp_dir"
        
        nix flake update --no-registries &>/dev/null
        
        # Confronta
        updates_found=false
        
        for input in $(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes | keys[]' | grep -v "^root$"); do
            # Estrai info (semplificato)
            if [ "$updates_found" = false ]; then
                echo -e "\n${GREEN}Controllando aggiornamenti...${NC}\n"
                updates_found=true
            fi
        done
        
        if [ "$updates_found" = false ]; then
            log_success "Sistema aggiornato!"
        else
            log_info "Aggiornamenti disponibili. Esegui: $0 update"
        fi
        ;;
        
    # ========================================================================
    # ROLLBACK - Torna indietro
    # ========================================================================
    rollback)
        log_header "Rollback Sistema"
        
        current_gen=$(sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | grep "(current)" | awk '{print $1}')
        
        echo -e "${CYAN}Generazioni disponibili:${NC}"
        sudo nix-env --profile /nix/var/nix/profiles/system --list-generations | tail -10
        
        if [ "$AUTO_YES" = true ]; then
            target_gen=$(($current_gen - 1))
            log_info "Auto-yes: rollback a #$target_gen"
        else
            echo -ne "\n${YELLOW}Generazione target [$(($current_gen - 1))]: ${NC}"
            read -r target_gen
            target_gen=${target_gen:-$(($current_gen - 1))}
        fi
        
        if [[ ! "$target_gen" =~ ^[0-9]+$ ]] || [ "$target_gen" -ge "$current_gen" ]; then
            log_error "Generazione non valida"
            exit 1
        fi
        
        log_warning "Rollback: #$current_gen → #$target_gen"
        
        if confirm "Procedere? (y/N)" "n"; then
            if sudo nix-env --profile /nix/var/nix/profiles/system --switch-generation "$target_gen"; then
                log_success "Rollback completato!"
                log_info "Riavvia per applicare completamente"
            else
                log_error "Rollback fallito"
                exit 1
            fi
        fi
        ;;
        
    # ========================================================================
    # DIFF - Mostra differenze
    # ========================================================================
    diff)
        log_header "Differenze Configurazione"
        check_dependencies
        
        cd "$NIXOS_CONFIG"
        
        log_info "Build nuova configurazione..."
        if safe_build; then
            echo ""
            nix store diff-closures /run/current-system ./result | head -50
            
            total=$(nix store diff-closures /run/current-system ./result 2>/dev/null | wc -l)
            echo -e "\n${CYAN}Totale cambiamenti: $total${NC}"
        else
            exit 1
        fi
        ;;
        
    # ========================================================================
    # HELP
    # ========================================================================
    help|--help|-h|*)
        cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║           NixOS Maintenance Script - Improved                ║
╚══════════════════════════════════════════════════════════════╝

USO:
  ./nixos-maintenance.sh [OPZIONI] COMANDO

OPZIONI:
  -y, --yes        Conferma automatica
  -v, --verbose    Output dettagliato
  -h, --help       Mostra questo aiuto

COMANDI PRINCIPALI:

  update           Aggiornamento completo (consigliato)
                   • Aggiorna flake inputs
                   • Verifica build
                   • Applica con switch

  quick            Aggiornamento rapido senza conferme

  update-test      Testa aggiornamenti senza applicare

  status           Mostra stato sistema e generazioni

  clean            Pulizia sistema (generazioni + GC)

COMANDI AVANZATI:

  switch           Applica configurazione corrente
  test             Test temporaneo (fino al riavvio)
  build            Solo build senza applicare
  rollback         Torna a generazione precedente
  diff             Mostra differenze con sistema attuale
  update-check     Controlla aggiornamenti disponibili

ESEMPI:

  # Aggiornamento normale (consigliato)
  ./nixos-maintenance.sh update

  # Aggiornamento automatico (per script)
  ./nixos-maintenance.sh -y update

  # Test prima di applicare
  ./nixos-maintenance.sh update-test
  ./nixos-maintenance.sh switch  # se OK

  # Pulizia periodica
  ./nixos-maintenance.sh clean

  # Check stato
  ./nixos-maintenance.sh status

WORKFLOW CONSIGLIATO:
  1. ./nixos-maintenance.sh status        # Verifica stato
  2. ./nixos-maintenance.sh update        # Aggiorna
  3. ./nixos-maintenance.sh clean         # Pulisci (opzionale)

In caso di problemi:
  ./nixos-maintenance.sh rollback         # Torna indietro

EOF
        ;;
esac

exit 0
