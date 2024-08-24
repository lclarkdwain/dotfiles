# Dotfiles

Personal dotfiles for (Windows + WSL:Ubuntu-20.04)

## Installation

### Using Make & Stow

```bash
sudo apt update
sudo apt install build-essential
```

1. Clone the repository to your home directory:

```bash
git clone https://github.com/lclarkdwain/dotfiles.git ~/.dotfiles
```

2. Navigate to the .dotfiles directory and run the setup:

```bash
cd ~/.dotfiles
make
```

### Using Bare Git Repository (Only Config)

```bash
bash <(curl -LfsS https://github.com/lclarkdwain/dotfiles/raw/main/.local/bin/install-bare)
```

## Configuration Requirements

- [Ble.sh](https://github.com/akinomyoga/ble.sh)
- [NeoVim](https://github.com/neovim/neovim/blob/master/INSTALL.md#linux)
- [TPM](https://github.com/tmux-plugins/tpm)
- [lazygit](https://github.com/jesseduffield/lazygit)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [NVM](https://github.com/nvm-sh/nvm?tab=readme-ov-file#installing-and-updating)
