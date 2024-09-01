# vim: set noexpandtab:
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := linux
PATH := $(DOTFILES_DIR)/.local/bin:$(PATH)
SHELL := /bin/bash

export XDG_CONFIG_HOME = $(HOME)/.config

export LAZYGIT_VERSION=$(shell curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')

all: $(OS)

# Ubuntu
linux: core-linux prepare packages link

prepare:
	mkdir -p \
		$(HOME)/.{config,local} \
		$(HOME)/.local/{bin,share,src,state,cache} \

core-linux:
	sudo apt update
	sudo apt full-upgrade -y

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

packages: packages-$(OS) packages-common rust-packages

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
	# Building Neovim (Debian/Ubuntu)
	@if [ ! -d $(HOME)/.local/src/neovim ]; then \
		git clone --depth=1 https://github.com/neovim/neovim.git -b stable $(HOME)/.local/src/neovim && \
			cd $(HOME)/.local/src/neovim && \
			CMAKE_BUILD_TYPE=RelWithDebInfo make && \
			cd build && \
			cpack -G DEB && \
			sudo dpkg -i nvim-linux64.deb; \
	fi
	# Lazygit
	curl -Lo $(HOME)/.local/src/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_$(LAZYGIT_VERSION)_Linux_x86_64.tar.gz" && \
		cd $(HOME)/.local/src && \
		tar xf lazygit.tar.gz lazygit && \
		sudo install lazygit /usr/local/bin

packages-common:
	# Setting up Git Submodules
	git submodule update --init
	# Setting up Rust
	curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable --profile default
	# Insalling Starship
	curl -sS https://starship.rs/install.sh | sh
	# TMUX
	@if [ ! -d $(XDG_CONFIG_HOME)/tmux/plugins/tpm ]; then \
		git clone https://github.com/tmux-plugins/tpm $(XDG_CONFIG_HOME)/tmux/plugins/tpm; \
	fi
	# Setting up NVM
	PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash' && \
		. $(XDG_CONFIG_HOME)/nvm/nvm.sh && \
		nvm install lts/iron && \
		npm i -g neovim

rust-packages:
	cargo install $(shell cat packages/rust)
