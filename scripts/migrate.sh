#!/usr/bin/env bash
# Script di migrazione alla nuova struttura modulare NixOS

set -e

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== NixOS Configuration Migration Script ===${NC}"
echo -e "${YELLOW}Questo script ti aiuterà a migrare alla nuova struttura modulare${NC}\n"

# Controllo se siamo nella directory corretta
if [ ! -f "flake.nix" ]; then
    echo -e "${RED}Errore: flake.nix non trovato. Assicurati di essere nella directory della configurazione NixOS${NC}"
    exit 1
fi

# Backup
echo -e "${BLUE}1. Creazione backup...${NC}"
BACKUP_DIR="../nix-config-backup-$(date +%Y%m%d-%H%M%S)"
cp -r . "$BACKUP_DIR"
echo -e "${GREEN}   ✓ Backup creato in: $BACKUP_DIR${NC}"

# Creazione nuova struttura
echo -e "\n${BLUE}2. Creazione struttura directory...${NC}"

# Directory principali
directories=(
    "config"
    "lib"
    "overlays"
    "profiles"
    "scripts"
    "modules/core"
    "modules/hardware"
    "modules/desktop"
    "modules/services"
    "modules/development"
    "modules/gaming"
    "hosts/laptop/slimbook"
    "hosts/desktop/gaming"
    "hosts/server/dev-server"
    "users/filippo"
    "users/modules"
    "assets/wallpapers"
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
    echo -e "   ${GREEN}✓${NC} Creata: $dir"
done

# Mapping dei file esistenti
echo -e "\n${BLUE}3. Migrazione file esistenti...${NC}"

# Funzione helper per spostare file
move_if_exists() {
    local source=$1
    local dest=$2
    if [ -f "$source" ]; then
        cp "$source" "$dest"
        echo -e "   ${GREEN}✓${NC} Migrato: $source → $dest"
    fi
}

# Hardware configurations
move_if_exists "hosts/slimbook/hardware-configuration.nix" "hosts/laptop/slimbook/hardware-configuration.nix"
move_if_exists "hosts/gaming/hardware-configuration.nix" "hosts/desktop/gaming/hardware-configuration.nix"
move_if_exists "hosts/dev-server/hardware-configuration.nix" "hosts/server/dev-server/hardware-configuration.nix"

# Secrets
echo -e "\n${BLUE}4. Mantenimento secrets...${NC}"
if [ -d "secrets" ]; then
    echo -e "   ${GREEN}✓${NC} Directory secrets mantenuta"
fi

# Creazione file README per ogni directory
echo -e "\n${BLUE}5. Creazione file README...${NC}"

cat > "profiles/README.md" << 'EOF'
# Profiles

Configurazioni per tipo di macchina:
- `base.nix`: Configurazione comune a tutti gli host
- `laptop.nix`: Configurazioni specifiche per laptop
- `desktop.nix`: Configurazioni specifiche per desktop
- `server.nix`: Configurazioni specifiche per server
EOF

cat > "modules/README.md" << 'EOF'
# Modules

Moduli riutilizzabili organizzati per categoria:
- `core/`: Configurazioni base del sistema
- `hardware/`: Configurazioni hardware
- `desktop/`: Desktop environment e GUI
- `services/`: Servizi di sistema
- `development/`: Ambienti di sviluppo
- `gaming/`: Configurazioni gaming
EOF

cat > "hosts/README.md" << 'EOF'
# Hosts

Configurazioni specifiche per host, organizzate per tipo:
- `laptop/`: Laptop e notebook
- `desktop/`: Desktop e workstation
- `server/`: Server headless

Ogni host contiene solo:
- `default.nix`: Override specifici dell'host
- `hardware-configuration.nix`: Configurazione hardware generata
EOF

echo -e "   ${GREEN}✓${NC} README creati"

# Creazione file di esempio
echo -e "\n${BLUE}6. Creazione file di configurazione...${NC}"

# Crea un makefile per comandi comuni
cat > "Makefile" << 'EOF'
# NixOS Configuration Makefile

HOSTNAME := $(shell hostname)
FLAKE := /etc/nixos

.PHONY: help
help:
	@echo "NixOS Configuration Management"
	@echo ""
	@echo "Comandi disponibili:"
	@echo "  make rebuild    - Rebuild e switch configurazione"
	@echo "  make test       - Test configurazione"
	@echo "  make update     - Update flake inputs"
	@echo "  make clean      - Garbage collection"
	@echo "  make check      - Check configurazione"
	@echo "  make diff       - Mostra differenze con sistema attuale"

.PHONY: rebuild
rebuild:
	sudo nixos-rebuild switch --flake .#$(HOSTNAME)

.PHONY: test
test:
	sudo nixos-rebuild test --flake .#$(HOSTNAME)

.PHONY: update
update:
	nix flake update

.PHONY: clean
clean:
	sudo nix-collect-garbage -d
	sudo nix-store --optimise

.PHONY: check
check:
	nix flake check

.PHONY: diff
diff:
	nixos-rebuild build --flake .#$(HOSTNAME)
	nix store diff-closures /run/current-system ./result
