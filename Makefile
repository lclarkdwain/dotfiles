# vim: set noexpandtab:
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell .local/bin/is-supported .local/bin/is-macos macos linux)
HOMEBREW_PREFIX := $(shell .local/bin/is-supported .local/bin/is-macos $(shell .local/bin/is-supported .local/bin/is-arm64 /opt/homebrew /usr/local) /home/linuxbrew/.linuxbrew)
PATH := $(HOMEBREW_PREFIX)/bin:$(HOME)/.cargo/bin:$(DOTFILES_DIR)/.local/bin:$(PATH)
SHELL := env PATH=$(PATH) /bin/bash
SHELLS := /private/etc/shells
BIN := $(HOMEBREW_PREFIX)/bin

export XDG_CONFIG_HOME = $(HOME)/.config

export LAZYGIT_VERSION=$(shell curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')

all: $(OS)

linux: core-linux prepare packages link

macos: core-macos prepare packages link

prepare:
	mkdir -p \
		$(HOME)/.{config,local} \
		$(HOME)/.local/{bin,share,src,state,cache}

core-linux:
	sudo apt update
	sudo apt full-upgrade -y

core-macos: brew git

link: stow-$(OS)
	for DIR in zsh bash; do \
		for FILE in $$(\ls -A $$DIR); do if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
			mv -v $(HOME)/$$FILE $(HOME)/$$FILE.bak; fi; done; \
	done
	mkdir -p "$(XDG_CONFIG_HOME)"
	stow -t "$(HOME)" bash
	stow -t "$(HOME)" zsh
	stow -t "$(XDG_CONFIG_HOME)" .config

unlink: stow-$(OS)
	stow --delete -t "$(HOME)" bash
	stow --delete -t "$(HOME)" zsh
	stow --delete -t "$(XDG_CONFIG_HOME)" .config
	for DIR in zsh bash; do \
		for FILE in $$(\ls -A $$DIR); do if [ -f $(HOME)/$$FILE.bak ]; then \
			mv -v $(HOME)/$$FILE.bak $(HOME)/$${FILE%%.bak}; fi; done; \
	done

stow-linux: core-linux
	is-executable stow || sudo apt install stow -y

stow-macos: brew
	is-executable stow || brew install stow

packages: packages-$(OS) packages-common rust-packages

packages-macos: brew-packages cask-apps

packages-linux:
	sudo apt update && sudo apt install -y \
		build-essential \
		cmake \
		curl \
		fd-find \
		fzf \
		gettext \
		jq \
		lua5.1 \
		lua5.4 \
		ninja-build \
		ripgrep \
		unzip \
		zsh
	# AWS CLI v2
	if aws --version >/dev/null 2>&1; then \
		echo "AWS CLI is already installed. Cleaning up existing installation..."; \
		sudo rm /usr/local/bin/aws /usr/local/bin/aws_completer; \
		sudo rm -rf /usr/local/aws-cli; \
	fi
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	sudo ./aws/install
	rm -rf aws awscliv2.zip
	aws --version
	# Neovim - from binary
	curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
	sudo rm -rf /opt/nvim
	sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
	sudo rm -rf nvim-linux-x86_64.tar.gz
	# Lazygit
	curl -Lo $(HOME)/.local/src/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_$(LAZYGIT_VERSION)_Linux_x86_64.tar.gz" && \
		cd $(HOME)/.local/src && \
		tar xf lazygit.tar.gz lazygit && \
		sudo install lazygit /usr/local/bin
	# Setting up Rust
	# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
	curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable --profile default
	# TMUX
	@if [ ! -f "$(HOME)/.local/src/tmux-3.5a.tar.gz" ]; then \
		curl -Lo "$(HOME)/.local/src/tmux-3.5a.tar.gz" "https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz"; \
	fi
	@tar -xzf "$(HOME)/.local/src/tmux-3.5a.tar.gz" -C "$(HOME)/.local/src/tmux-3.5a"
	@cd "$(HOME)/.local/src/tmux-3.5a" && \
		sudo apt install -y libevent-dev libncurses-dev byacc && \
		./configure && \
		make && \
		sudo make install

packages-common:
	# Setting up Git Submodules
	git submodule update --init
	# Installing Starship
	curl -sS https://starship.rs/install.sh | sh
	# Setting up NVM
	PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash' && \
		. $(XDG_CONFIG_HOME)/nvm/nvm.sh && \
		nvm install lts/iron && \
		npm i -g neovim

brew:
	is-executable brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

git: brew
	brew install git git-extras

brew-packages: brew
	brew bundle --file=$(DOTFILES_DIR)/packages/brew || true

cask-apps: brew
	brew bundle --file=$(DOTFILES_DIR)/packages/cask || true

vscode-extensions: cask-apps
	# TODO: Add vscode extensions

node-packages:
	# TODO: Add node packages

rust-packages:
	cargo install $(shell cat packages/rust)
