# vim: set noexpandtab:
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
DISTRO := $(shell . /etc/os-release 2>/dev/null && echo $$ID || echo unknown)

XDG_CONFIG_HOME ?= $(HOME)/.config
CLAUDE_PERSONAL_DIR ?= $(HOME)/.claude-personal

.PHONY: all install link unlink backup restore

DRY_RUN ?= false
STOW_CMD = $(if $(filter $(DRY_RUN),true),echo stow,stow)
RM_CMD = $(if $(filter $(DRY_RUN),true),echo rm -rf,rm -rf)
GIT_CMD = $(if $(filter $(DRY_RUN),true),echo git,git)
MKDIR_CMD = $(if $(filter $(DRY_RUN),true),echo mkdir,mkdir)
XDG_MIME_CMD = $(if $(filter $(DRY_RUN),true),echo xdg-mime,xdg-mime)

all: install link

# antidote is a git submodule. A clone made without --recursive leaves
# .config/zsh/.antidote as an empty directory, and every new zsh then fails to
# source antidote.zsh.
.PHONY: submodules
submodules:
	@if [ ! -e .config/zsh/.antidote/antidote.zsh ]; then \
		echo "Initializing git submodules..."; \
		$(GIT_CMD) submodule update --init; \
	fi

link: backup submodules
	@echo "$(DOTFILES) Linking configurations..."
	@# Real dirs, so stow doesn't fold ~/.local/share into the repo
	@$(MKDIR_CMD) -p $(XDG_CONFIG_HOME) $(HOME)/.local/share/applications
	@$(STOW_CMD) -t $(HOME) zsh
	@echo "Linking .config (removing any conflicts)..."
	@for dir in .config/*/; do \
		folder=$$(basename $$dir); \
		if [ -e "$(XDG_CONFIG_HOME)/$$folder" ] && [ ! -L "$(XDG_CONFIG_HOME)/$$folder" ]; then \
			echo "Removing conflicting: $(XDG_CONFIG_HOME)/$$folder"; \
			$(RM_CMD) "$(XDG_CONFIG_HOME)/$$folder"; \
		fi; \
	done
	@$(STOW_CMD) -t $(XDG_CONFIG_HOME) .config
	@$(STOW_CMD) -t $(HOME)/.local .local
	@# The local Zoom.desktop hides the system one, so GLib apps (Zen) lose its link handlers
	@if command -v xdg-mime >/dev/null; then \
		$(XDG_MIME_CMD) default Zoom.desktop x-scheme-handler/zoommtg x-scheme-handler/zoomus x-scheme-handler/zoomphonecall; \
	fi
	@echo "Linking personal Claude Code config..."
	@$(STOW_CMD) --no-folding -t $(HOME) claude
	@$(MAKE) --no-print-directory claude-settings

unlink:
	@echo "Unlinking configurations..."
	@stow -D -t $(HOME) zsh
	@stow -D -t $(XDG_CONFIG_HOME) .config
	@stow -D -t $(HOME)/.local .local
	@stow -D --no-folding -t $(HOME) claude

.PHONY: claude-settings
claude-settings:
	@if [ -e "$(CLAUDE_PERSONAL_DIR)/settings.json" ]; then \
		echo "Keeping existing $(CLAUDE_PERSONAL_DIR)/settings.json"; \
	elif [ "$(DRY_RUN)" = "true" ]; then \
		echo "Dry-run: would seed $(CLAUDE_PERSONAL_DIR)/settings.json"; \
	else \
		mkdir -p "$(CLAUDE_PERSONAL_DIR)" && \
		cp scripts/claude/settings.personal.json "$(CLAUDE_PERSONAL_DIR)/settings.json" && \
		echo "Seeded $(CLAUDE_PERSONAL_DIR)/settings.json"; \
	fi

backup:
	@echo "Creating backups for existing configurations... (max 3 and overwrites the oldest)"
	@if [ "$(DRY_RUN)" = "true" ]; then \
		echo "Dry-run: would create $(HOME)/backups/backup_<timestamp> and prune all but the newest 3"; \
	else \
		BACKUP_DIR=$(HOME)/backups/backup_$(shell date +%Y%m%d%H%M%S) && mkdir -p $$BACKUP_DIR && \
		ls -dt $(HOME)/backups/backup_* | tail -n +4 | xargs -r rm -rf && \
		cp -rL $(HOME)/.zshrc $$BACKUP_DIR/.zshrc 2>/dev/null || true && \
		cp -rL $(XDG_CONFIG_HOME)/zsh $$BACKUP_DIR/zsh 2>/dev/null || true; \
	fi

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
