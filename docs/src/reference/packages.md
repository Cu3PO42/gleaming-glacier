---
title: Included Packages
---

# Packages

My configuration includes a number of packages I needed while building my configurations.
This includes both programs I have built myself, packages whose source code is vendored, as well as derivations for third-party software.

Not all packages are supported on all platforms.

Pleaes note that this documentation is partial and not all programs are documented.

## macOS exclusive

### ifstat

This is the Mac-equivalent of the well-known `ifstat` on Linux.

### ical-buddy

A command line tool to read from the local calendar on your Mac.

### mac-keybind-helper

A SwiftUI application for visualizing keybinds used by [Maestro](/features/mage), a `which-key.nvim` inspired way of organizing keybinds.

### mac-shell-wrapper

A tiny stub that is intended to be set as a user's login shell and `exec`s the real shell.
This is necessary to work around a race condition when using a login shell installed via Nix on a system with disk encryption.
`/nix` must live on a separate partition due to macOS restrictions on folders in the root directory and may be decrypted and mounted only after the first user logs in.
Programs starting at login, especially those restoring from a previous session may try to launch the login shell before `/nix` is available, causing these processes to fail.

To avoid this, this wrapper is installed to `/usr/local/bin`, will wait for `/nix` to mount and then executes the shell.
This also avoids needing to add every shell to `/etc/shells`.

You should not use this package directly, but through my `chsh` nix-darwin module.

### mac-wm-helpers

A variety of scripts that are used as part of my configuration on macOS.
It enables switching of the active workspace and showing iTerm as a drop-down terminal.

### sketchybar-app-font

A font containing app icons for use in Sketchybar, a status bar for macOS.

## Linux exclusive

### illogical-impulse

### libadwaita-without-adwaita

A patched version of `libadwaita` that allows using GTK themes that aren't Adwaita.
Needed for our [GTK module for Chroma](/features/chroma#gtk).  
This is a direct port of the eponymous package from the AUR.

### swimctl

The companion app to the [Copper Swim](/features/swim) module.

### systemctl-toggle

A minimal wrapper script that starts a unit if it was previously stopped, or stops it if it was running.

### catppuccin-qt5ct

The Catppuccin themes for qt5ct from their upstream.

### gtkrc-reload

A small utility to force GTK2 apps to reload their theme.
Also integrated with [Chroma](/features/chroma).

### op-wsl-proxy

A small utility wrapper around the 1Password CLI that, when running in WSL, forwards the requests to the 1Password CLI running in Windows to enable integration with the desktop app.

### sddm-theme-corners

The "corners" theme for the SDDM login manager.

### wsl-ssh-agent

A utility for use in WSL that enables you to use your Windows' SSH agent in WSL.
This is extremely useful if you already have an SSH agent configured, for example through 1Password that you also want to use in WSL without manually copying your key over.

Simply install it and include `source "$(which wsl-ssh-agent)"` or the equivalent thereof in your `.bashrc` or other shell config.

## Common

### chromactl

The companion applicationt to [Copper Chroma](/features/chroma).
It is used to switch the active theme.

### dynachrome

### liga-sfmono-nerd-font

### maestro

### mage

The companion app to [Copper Mage](/features/mage).
It is used to encrypt and decrypt new and existing secrets.

### materialyoucolor

### microtex

### plate

An app to provision, update, remote unlock, ... new and existing servers running NixOS.
See the [documentation](/features/plate).

### rga-fzf

## Hyprdots

These scripts also only work on Linux, but are specific to my efforts to port [prasanthrangan's Hyprdots](https://github.com/prasanthrangan/hyprdots) to Home-Manager and NixOS.

### misc-scripts-hyprdots

### rofi-launchers-hyprdots

### waybar-confgen-hyprdots

### wlogout-launcher-hyprdots

### nailgun

## Legacy Packages

### replace-dependencies

This is a backport of an upstream Nix function `replaceRuntimeDependencies`.
Note that this is not a package, but essentially a library function, therefore it's in legacy package.
As of late 2024, this function has been merged upstream, so you probably don't need this.
