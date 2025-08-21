---
title: Maestro
---

# Maestro

Maestro is my system to manage keybindings on Linux and macOS.
It is inspired by the `which-key.nvim` system.
This means that once you press a defined leader key, you navigate a nmenu of key bindings using simple keys.
If, after a couple of seconds, you do not activate any binding, a menu pops up on screen to show you your current possible bindings.
It updates as you press additional keys.

## Supported Systems

Currently, keybindings are supported using skhd on macOS and Hyprland on Linux.
Support for additional desktop environments would be relatively straight forward to implement.

## Configuration

Maestro itself is a daemon that controls whether and how to show which keymap help and when to reset our modal keymaps.
It needs to have the various commands and for showing and hiding help configured.
We provide reasonable implementatons that register themselves for Linux, based on AGS, and for macOS.

They are set up automatically by the `hyprland-keybinds` and `skhd-keybinds` modules respectively.
They also provide the basis for setting up keybinds via Hyprland's native bind feature and SKHD.
