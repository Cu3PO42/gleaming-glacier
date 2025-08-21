---
title: Highlights
---

# Highlights

These dotfiles configure ...

* NixOS Desktops with
  * **[Hyprland](https://hyprland.dev)** with a bunch of plugins
  * Almost a full DE based on **[AGS](https://github.com/Aylur/AGS)**
  * My own system for **modal keymaps**
  * A powerful **theming** system
  * Full Disk Encryption on **ZFS**
  * Easy Deployment
* NixOS Servers with
  * **Remote unlocking** during boot
  * **Impermanence**
  * Full Disk Encryption on **ZFS**
  * Easy Deployment
* macOS with
  * **[Yabai](https://github.com/koekeishiya/yabai)** tiling window manager
  * **[SketchyBar](https://github.com/FelixKratz/SketchyBar)**
  * **[skhd](https://github.com/koekeishiya/skhd)** for model keymaps

To this end, I have developed some features I like a lot. They are listed here!

### [Copper Chroma](/features/chroma)

My very own theming framework.
It is designed to play nicely with Home-Manager while making theme switches easy and fast without requiring a rebuild or whole Home-Manager activation.
Its themes consists of themes for all supported applications and are switched dynamically at the same time.

It supports both macOS and Linux and is easily extensible for additional applications.

### [Copper Plate](/features/plate)

My home-grown, simple provisioning system.
It supports installing your NixOS configuration of choice on a server via [nixos-anywhere](https://github.com/nix-community/nixos-anywhere), supplying disk encryption keys to servers via SSH running in the initrd, and even generating custom installer images that can automatically install the correct configuration on a PC while securely deploying any necessary secrets!

### [Copper Mage](/features/mage)

My abstraction to make [Agenix](https://github.com/ryantm/agenix) more convenient to use.

### [Maestro](/features/maestro)

Maestro is my `which-key.nvim` inspired system for managing keybindings.
I enjoy navigating my system using my keyboard, but I am notoriously bad at remembering them.
This is why I am using mnenonics arranged in multiple layers starting with a leader key and also have an overlay to remind me.
If keysbinds are activated but none is pressed, a small menu will pop up that you can navigate to find the right one and activate it.
This is supported both on macOS and Linux with native UIs for each.

### Gleaming Framework

My Flake contains not just my own configuration, but also provides a generic framework for structuring and writing your own Flakes with packages, modules and featuers.

It prefers convention over configuration to make it easy to get started while still providing all necessary escape hatches to customize anything and everything.

The easiest way to get started with the Gleaming framework is to use the provided template, see [the instructions](/usage#getting-started).
If you already have an existing Flake, you can simply use my modules and packages if you prefer.
