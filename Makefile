DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PATH := $(DOTFILES_DIR)/.local/bin:$(PATH)

export XDG_CONFIG_HOME = $(HOME)/.config

all: linux

linux: core-linux link

core-linux:
	sudo apt update
	sudo apt full-upgrade -y

link: stow-linux
	for FILE in $$(\ls -A rc); do if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
		mv -v $(HOME)/$$FILE $(HOME)/$$FILE.bak; fi; done
	mkdir -p "$(XDG_CONFIG_HOME)"
	stow -t "$(HOME)" rc
	stow -t "$(XDG_CONFIG_HOME)" .config

unlink: stow-linux
	stow --delete -t "$(HOME)" rc
	stow --delete -t "$(XDG_CONFIG_HOME)" .config
	for FILE in $$(\ls -A rc); do if [ -f $(HOME)/$$FILE.bak ]; then \
		mv -v $(HOME)/$$FILE.bak $(HOME)/$${FILE%%.bak}; fi; done

stow-linux: core-linux
	is-executable stow || sudo apt install stow -y
