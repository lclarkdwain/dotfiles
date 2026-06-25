# vim: set noexpandtab:
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
DISTRO := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo unknown)

XDG_CONFIG_HOME ?= $(HOME)/.config

.PHONY: all install link unlink backup restore

DRY_RUN ?= false
STOW_CMD = $(if $(filter $(DRY_RUN),true),echo stow,stow)
MKDIR_CMD = $(if $(filter $(DRY_RUN),true),echo mkdir -p,mkdir -p)

all: install link

prepare:
	@echo "Preparing required directories..."
	@$(MKDIR_CMD) $(HOME)/.claude

link: prepare backup
	@echo "$(DOTFILES) Linking configurations..."
	@$(STOW_CMD) -t $(HOME) zsh
	@echo "Linking .config (removing any conflicts)..."
	@for dir in .config/*/; do \
		folder=$$(basename $$dir); \
		if [ -e "$(XDG_CONFIG_HOME)/$$folder" ] && [ ! -L "$(XDG_CONFIG_HOME)/$$folder" ]; then \
			echo "Removing conflicting: $(XDG_CONFIG_HOME)/$$folder"; \
			rm -rf "$(XDG_CONFIG_HOME)/$$folder"; \
		fi; \
	done
	@$(STOW_CMD) -t $(XDG_CONFIG_HOME) .config
	@$(STOW_CMD) -t $(HOME)/.local .local

unlink:
	@echo "Unlinking configurations..."
	@stow -D -t $(HOME) zsh
	@stow -D -t $(XDG_CONFIG_HOME) .config
	@stow -D -t $(HOME)/.local .local

backup:
	@echo "Creating backups for existing configurations... (max 3 and overwrites the oldest)"
	@BACKUP_DIR=$(HOME)/backups/backup_$(shell date +%Y%m%d%H%M%S) && mkdir -p $$BACKUP_DIR && \
	ls -dt $(HOME)/backups/backup_* | tail -n +4 | xargs -r rm -rf && \
	cp -rL $(HOME)/.zshrc $$BACKUP_DIR/.zshrc 2>/dev/null || true && \
	cp -rL $(XDG_CONFIG_HOME)/zsh $$BACKUP_DIR/zsh 2>/dev/null || true

restore:
	@echo "Available backups:"
	@ls -dt $(HOME)/backups/backup_* | nl
	@read -p "Enter the number of the backup to restore: " BACKUP_NUM && \
	BACKUP_DIR=$$(ls -dt $(HOME)/backups/backup_* | sed -n "$${BACKUP_NUM}p") && \
	echo "Restoring from $$BACKUP_DIR..." && \
	cp -r $$BACKUP_DIR/.zshrc $(HOME)/.zshrc 2>/dev/null || true && \
	cp -r $$BACKUP_DIR/zsh $(XDG_CONFIG_HOME)/zsh 2>/dev/null || true

.PHONY: uninstall
uninstall: unlink restore
	@echo "Unlinking and restoring backup completed."

dry-run:
	@$(MAKE) link DRY_RUN=true

install:
ifeq ($(OS), darwin)
	@echo "detected macos"
	# TODO: @bash scripts/install-macos.sh
else ifeq ($(DISTRO), arch)
	@echo "detected arch linux"
	@bash scripts/install-arch.sh
else ifeq ($(DISTRO), ubuntu)
	@echo "detected ubuntu"
	@bash scripts/install-ubuntu.sh
else ifeq ($(DISTRO), fedora)
	@echo "detected fedora"
	# TODO: @bash scripts/install-fedora.sh
else
	@echo "unsupported os or distribution: $(OS) $(DISTRO)"
	@exit 1
endif
