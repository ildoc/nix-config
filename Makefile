# NixOS Configuration Makefile

HOSTNAME := $(shell hostname)
FLAKE := .

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
	@echo "  make format     - Format codice Nix"
	@echo "  make show       - Mostra struttura flake"
	@echo "  make develop    - Entra nella dev shell"

.PHONY: rebuild
rebuild:
	sudo nixos-rebuild switch --flake $(FLAKE)#$(HOSTNAME)

.PHONY: test
test:
	sudo nixos-rebuild test --flake $(FLAKE)#$(HOSTNAME) --show-trace

.PHONY: update
update:
	nix flake update

.PHONY: clean
clean:
	sudo nix-collect-garbage -d
	sudo nix-store --optimise

.PHONY: check
check:
	nix flake check --show-trace

.PHONY: diff
diff:
	nixos-rebuild build --flake $(FLAKE)#$(HOSTNAME)
	nix store diff-closures /run/current-system ./result

.PHONY: format
format:
	nix fmt

.PHONY: show
show:
	nix flake show

.PHONY: develop
develop:
	nix develop
