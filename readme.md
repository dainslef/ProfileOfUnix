# Profiles of my UNIX environment
Some UNIX tools configurations:

- [`SSH (ssh_config)`](ssh_config) Secure Shell
- [`VIM (.vimrc)`](.vimrc) UNIX editor
- `Git` Distributed version control system
	- [`.gitconfig`](.gitconfig) Git core configuration
	- [`.gitignore`](.gitignore) Git ignore list
- [`Syncthing (.stignore)`](.stignore_synced) A peer-to-peer file synchronization application
- [`Dunst (dunstrc)`](dunstrc) A lightweight notification daemon

NixOS confugurations:

- [`configuration.nix`](./nixos/configuration.nix) NixOS core configuration
- [`custom-configuration.nix`](./nixos/custom-configuration.nix) NixOS custom define options
- [`user-configuration.nix`](./nixos/user-configuration.nix) NixOS user specific options

Window manager configurations:

- [`Qtile (config.py)`](./window_manager/qtile/config.py) Qtile window manager
- [`AwesomeWM (rc.lua)`](./window_manager/awesome/rc.lua) AwesomeWM
- `xmonad` xmonad window manager
	- [`xmonad.hs`](./window_manager/xmonad/xmonad.hs) xmonad window manger configuration
	- [`xmobarrc.hs`](./window_manager/xmonad/xmobarrc.hs) xmobar, status bar for xmoand window manager

Theme configurations:

- [`Cursor theme (index.theme)`](./theme/index.theme) X Window cursor theme
- [`GTK3 (settings.ini)`](./theme/settings.ini) GTK3 theme configuration
- [`GTK2 (.gtkrc-2.0)`](./theme/.gtkrc-2.0) GTK2 theme configuration
