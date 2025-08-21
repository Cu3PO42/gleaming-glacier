---
title: Notes on using Nix on macOS
---

# Notes on using Nix on macOS

macOS is a supported platform for Nix.
It can be managed via `nix-darwin`, which replicates much of the functionality of NixOS on Darwin.
Additionally, any users can manager their home folders via Home-Manager, just as on NixOS and other Linux distributions.

Unfortunately there are some limitations and gotchas that need to be taken into consideration.

## Configuration of the PAM module for Touch ID

My macOS configuration adds a PAM module to authenticate users via TouchID.
This is relevant in particular to allow `sudo` to function via TouchID.
This breaks on macOS updates, but can be fixed by simply activating the current configuration again.

## Permission Prompts

macOS has a fine-grained permission model that requires some permissions to be granted via the System Settings UI.
Upon activating your nix-darwin or Home-Manager confinguration, you may be prompted to grant some applications certain permissions.
You need to accept these for correct functionality.

It is unfortunately a limitation of Nix, that binaries are not signed and notarized in the classic macOS sense.
As a consequence, every new version of a program has its own identity and permissions need to be granted again.
At that time you may remove the permissions for the older versions.

## Handling of some configuration files

Some configuration files, including `karabiner.json` and `iterm.plist` are not handled correctly via Home-Manager.
Their relevant applications overwrite the symlinks that Home-Manager creates with new contents of their configuration.
This causes subsequent activations of HM to fail unless `-b <backup-extension>` is passed.
I currently know no workaround except to disable the relevant features after initial activation.
