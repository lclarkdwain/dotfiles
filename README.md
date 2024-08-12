# 🛠️ Dotfiles

## 🚀 Installation

1. Clone the repository to your home directory:
```bash
git clone https://github.com/lclarkdwain/dotfiles.git ~/.dotfiles
```

2. Navigate to the .dotfiles directory and run the setup:
```bash
cd ~/.dotfiles
make
```

## 🧰 Tools

Alacritty
To use Alacritty in WSL and apply the alacritty.toml configuration from your dotfiles:

1. Create the `alacritty` directory in `%APPDATA%`:
```cmd
mkdir %APPDATA%\alacritty
```
```cmd
mklink C:\Users\lclar\AppData\Roaming\alacritty\alacritty.toml \\wsl.localhost\Ubuntu-24.04\home\lclarkdwain\.dotfiles\.config\alacritty\alacritty.toml
```

TMUX
Your tmux configuration is included in the dotfiles. Simply install tmux and it will automatically use the configuration.

## 📦 Packages

NVIM (LazyVim)
-- lazygit
-- stylua

Rust & Cargo

## Others

NerdFont