# dotfiles

## Installation

1.
```bash
git clone https://github.com/lclarkdwain/dotfiles.git ~/.dotfiles
```

2.
```bash
cd ~/.dotfiles
make
```

## Tools

To use Alacritty in windows and using alacritty.toml from dotfiles (create alacritty directory first in %APPDATA%)
```cmd
mklink C:\Users\lclar\AppData\Roaming\alacritty\alacritty.toml \\wsl.localhost\Ubuntu-24.04\home\lclarkdwain\.dotfiles\.config\alacritty\alacritty.toml
```
