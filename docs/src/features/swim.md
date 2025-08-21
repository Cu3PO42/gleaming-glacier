---
title: Copper Swim – swww orchestration
---

# Copper Swim

Swim is my minimal system on top of [swww](https://github.com/LGFae/swww), a wallpaper daemon for Wayland.
In other words, it is used to configure your wallpapers when using a Wayland compositor that is not a complete desktop environment, like Gnome and KDE.

Swim makes swww's capabilities more accessible by allowing the user to configure a folders of background images and cycling between them.  
It also works around some common issues and it integrates neatly with my [Chroma](/features/chroma) theming system to allow per-heme wallpapers and other parts of my configuraiton.

## Usage

Swim is implemented as a Home-Managaer module, which you must include and activate with `copper.swim.enable = true`.
You should either set a `wallpaperDirectory` directly, which may be in the Nix store, but is not required to be, or by enabling integration with [Chroma](/features/chroma) and configuring wallpapers through it.

You can also enable a `systemd` service that automatically restores configuration on boot.
This is recommended for most situations to deal with multi-monitor configurations gracefully.
Set `copper.swim.systemd.enable = true` and choose a target that should contain this service as `copper.swim.systemd.installTarget`.
For example, in my configuration, this is a target that I launch as part of my Hyprland configuration.

Alternatively, you want to call `swimctl activate` as part of your compositor configuration after `swww` has been started.

## CLI

Swim is accompanied by a CLI application `swimctl` that you use to interact with it.
The following commands are supported:

* `activate`: activate the current configuration. You probably do not need to call this manually, it is managed by the systemd service.
* `next`: cycles to the next available wallpaper
* `previous`: cycles to the previous wallpaper
* `select`: activate a particular wallpaper by name. It must be stored in teh atcive wallpaper directory
* `list`: print a list of all available wallpapers, one per line.