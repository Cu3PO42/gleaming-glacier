---
title: Flake Outputs
---

# Flake Outputs

This Flake contains modules for building NixOS, nix-darwin, and Home-Manager configurations, these configurations themselves, packages, as well as themes for my [Chroma theming system](/features/chroma).

The structure of these outputs is defined by the [Gleaming Autoload](/features/gleaming-autoload) module.
It populates all of the Flake's outputs by reading the files contained in the repository.

This document contains a possibly incomplete list of all the elements included in this Flake.
It does not document any of the options introduced by these modules.
Right now, you will need to check the source code of my modules for these options.
However, I plan to generate documentation pages at some point in the future.

::: info
The majority of my configurations are seperated into what I call *feature modules*.
While they can be toggled on and off and may occasionally have their own options, they are fundamentally my configurations and not necessarily for generic use.
They are a great option if you simply wish to copy my configuration, however.

To enable a feature module, set `copper.feature.<name>.enable = true`.
Unless enabled they have no effect, so are safe to include by default.
For convenience (and legacy reasons), there is also an option `copper.features` that can be set to a list of feature names that will be enabled.
:::

### NixOS Modules

* `accountsservice-default`: supports setting default settings for `accountsservice`
* `declarative-user-icons`: declaratively set a user icon using `accountsservice`

#### Features

* `_1password`: installs the 1Password GUI and CLI
* `amd`: support for (modern) AMD GPUs
* `base`: this mostly sets up Nix settings and installs some basic packages I want on every system
* `default-user`: sets up my user with my keys and default settings
* `hetzner-server`: system-specific settings generic to all Hetzner Cloud servers
* `home-manager`: sets up the NixOS Home-Manager module to be compatible with my configs
* `hyprland`: installs Hyprland, related services, and sets up any configuration that cannot be configured through Home-Manager
* `impermanence`: configures paths for the [Impermanence module](https://nixos.wiki/wiki/Impermanence) (TL;DR `/` is erased on every boot)
* `locale-de`: sets locale settings to reasonable values for Germany, but keep language English
* `luks-tpm`: unlocks a LUKSv2 encrypted partition at boot via TPM
* `nvidia`: configures Nvidia drivers and Nvidia-specific workarounds
* `quiet-boot`: turns off most logging messages during boot for desktop settings
* `remote-unlock`: configures an SSH server in initrd so we can submit a disk encryption key; useful for servers
* `secure-boot`: configures Secure Boot via [Lanzaboote](https://github.com/nix-community/lanzaboote)
* `server`: Server-specific settings (OpenSSH, Firewall, etc.)
* `zfs`: sets up ZFS and optionally enables automatic formatting for a single disk

### Home-Manager Modules

* `copper-chroma`: my own theming system with support for theme switching without rebuilds; also has a number of submodules adding support for a variety of applications; see [Chroma](/features/chroma)
* `copper-desktop-environment`: a tiny module that recognizes conflicts in which multiple of a certain kind of tool are enabled that are mutually incompatible, e.g. multiple Polkit agents
* `copper-maestro`: configure my keyboard shortcut helper `maestro` that is designed to help you remember your modal keybinds
* `copper-swim`: my system for managing dynamic wallpapers via swww
* `hyprland-keybinds`: adds a declarative way to manage modal keymaps for Hyprland; features integration with Maestro
* `lunarvim`: an attempt to package [LunarVim](https://www.lunarvim.org), a NeoVim distribution, for NixOS by replicating the setup created by its installer script
* `replace-dependencies`: brings the `system.replaceDependencies` option from NixOS to Home-Manager
* `rofi`: a slightly modified version of the upstream Rofi module from HM that in needed for [Chroma](/features/chroma)
* `skhd-keybindings`: adds a way to configure model keymaps for skhd in Nix; features Maestro integration
* `swww`: defines a systemd service for swww

#### Features

* `catpuccin`: configures the Catppuccin theme for a lot of applications; simply a frontend to [Chroma](/features/chroma)
* `chroma`: enables [Chroma](/features/chroma) and loads my themes
* `cli`: configures tools I like to use on the CLI, such as ripgrep, fzf, jq, and tokei
* `copilot`: enables GitHub Copilot for Fish (does not include an access token)
* `fish`: configures Fish to my preferences
* `git`: sets up my Git config, including delta and author information
* `link-config`: configures the `copper-file` module to symlink configs from this checkout rather than the store
* `lunarvim`: installs lunarvim
* `neovim`: installs my standard NeoVim config using NvChad
* `nixosBase`: some basic settings when Home-Manager is used as a NixOS module
* `rust`: configures rustup
* `standaloneBase`: configures Nix settings when Home-Manager is used standalone
* `wezterm`: links my WezTerm config
* `wsl`: configures some helpful settings when Nix is used from inside WSL
* `darwin/base`: macOS-specific configurations that don't have anywhere else to be. In particular: 1Password SSH Agent
* `darwin/iterm2`: iTerm2 configuration
* `darwin/orb`: sets up SSH for connection to OrbStack virtual machines
* `darwin/wm`: configures Yabai, Sketchybar, and skhd
* `nixos/_1password`: configures SSH and Git commit signing via 1Password
* `nixos/argyrodite`: my very own AGS config
* `nixos/dunst`: sets up Dunst as a notification daemon
* `nixos/hyprland`: configures Hyprland to my liking, including multi-modal keybindings
* `nixos/hyprlock`: configues Hypridle and Hyprlock
* `nixos/rofi`: configures Rofi as in [prasanthrangan's Hyprdots](https://github.com/prasanthrangan/Hyprdots)
* `nixos/swaylock`: sets up swaylock with swayidle
* `nixos/swim`: configures my wallpaper manager with integration for [Chroma](/features/chroma)
* `nixos/waybar-hyprdots`: sets up the Waybar configuration from [prasanthrangan's Hyprdots](https://github.com/prasanthrangan/Hyprdots)
* `nixos/waybar`: common configurations for Waybar
* `nixos/wlogout`: configures Wlogout as in [prasanthrangan's Hyprdots](https://github.com/prasanthrangan/Hyprdots)

### nix-darwin Modules

* `chsh`: can be used to set the shell of an existing user. This is useful because `users.users` can only be used to manage the shell of newly created users; this also contains a thin wrapper that works around a race condition when using FileVault
* `neo2`: sets up the Neo2 keyboard layout
* `default-user`: sets up the option for a username that is used in various other locations, for example for the user that will own the final Homebrew installation
* `keyboard-layout`: a WIP attempt to set the enabled keyboard layouts for a user. It doesn't work consistently yet and I don't use it.

#### Features

* `apps`: installs Desktop apps I commonly need
* `base`: configures Nix settings
* `cli`: settings that concern themselves with the command line. Currently: `sudo` via Touch ID and indexing for `nix-search`
* `defaults`: sets various system preferences that don't go anywhere else. Currently: enabling debugging in Safari
* `finder`: configures the Finder according to my preferences
* `fish`: installs fish and makes it the login shell for the `defaultUser`
* `install-brew`: install and configure Homebrew via [nix-homebrew](https://github.com/zhaofengli/nix-homebrew)
* `keyboard`: sets up my keyboard, in particular installs Neo 2 and sets key repeat settings
* `known-hashes`: nix-darwin will not overwrite some required files unless it knows they are in a 'default' configuration. This adds hashes for additional known defaults
* `mouse`: configures mouse and trackpad settings such as sensitivity, scrolling direction, and gestures
* `orb-builder`: configures a {aarch64,x86_64}-linux builder via NixOS running in [OrbStack](https://orbstack.dev)
* `wm`: installs yabai, Sketchybar, and skhd

### Common Modules

* `copper-mage`: a module to set up [Mage](/features/mage) for easy configuration of secrets
* `copper-patches`: a helper to apply patches to `nixpkgs`. By setting `copper.patches.<pkg>` to any list of patch files, an overlay is created that uses `overrideAttrs` on `<pkg>` to add the specified patches

### Flake Modules

* `allow-unfree`: configures the Nixpkgs instance used by the Flake to allow unfree packages
* `autoload`: automatically populates Flake outputs from the file hiererachy; see [the dedicated page](/features/gleaming-autoload)
* `base`: contains base settings recommended for all Flakes
* `copper-chroma`: configures the Flake outputs for [Chroma](/features/chroma)
* `copper-config`: defines outputs for configurations for other modules, including [Plate](/features/plate) and [Mage](/features/mage)
* `copper-mage`: adds type definitions for my [Mage](/features/mage) configuration
* `copper-plate`: adds configuration scripts necessary for use of [Plate](/features/plate)
* `default-overlays`: generates two overlays as an output. Particularly `additions`, which adds a namespace to nixpkgs of the same name as the namespace of your Flake, containing all of its packages and legacy packages. And `flake-inputs`, which adds `${namespace}-inputs` containing the package or legacyPackages for all Flake inputs
* `gleaming-modules`: instantiates all of the [Gleaming modules](#gleaming-modules) and adds the resulting modules to the Flake's outputs
* `gleaming`: configures common options for Flakes based on Gleaming Glacier
* `inherit-copper`: relevant only for configurations derviving from mine; adds all of my modules and feature modules to your configurations

### Templates

* `system`: A Flake that can be used to define your own system and user configs based on the frameworks introduced in this flake.

I plan to also keep templates for the development of projects in various languages here.

### Packages

For a list of packages, see [the dedicated page](./packages).

### Apps

* `bootstrap`: a wrapper srcipt used to activate configurations for the very first time. See [Getting Started](#getting-started) for usage examples
* `generate`: templates a new host or user configurations. Set [Getting Started](#getting-started) for its usage.
* `set-hostname`: sets the hostname of the current system. Abstracts over various systems, such as macOS, Linux with systemd and Linux without systemd

# Gleaming modules

There are also a number of modules that are useful not only to my configuraton, but to any configuration based on Gleaming Glacier.
Thus, they can be instantiated for every Flake based on its namespace.
They are defined in the `gleaming/` folder and are seperated by the system for which they are intended.
Like normal modules, there is also a common option.

### Home-Manager Modules

* `file`: an abstraction layer used for linking or copying config files. By default, files are linked from the Nix Store, making it easier to switch back to previous generations, but they can also be linked to the location of the repository by setting

### Common Modules

* `features`: a trivial helper that allows setting `${namespace}.features = [...]` instead of a number of `${namespace}.feature.<name>.enable = true`. This exists mainly for legacy reasons.
```
copper.file.symlink = {
  enable = true;
  base = "/path/to/repo";
};
```
* `per-system`: a helper module to make it more easy to access any packages coming from your own Flake in your own configurations. It allows you to write `${namespace}.packages.yourpackage` rather than having to write `origin.self.packages.${pkgs.hostPlatform.system}.yourpackage`. Additionally, it allows to build those packages not with your Flake's global nixpkgs instance, but rather the one from your configuration.