---
title: Copper Plate
---

# Copper Plate

Copper Plate (as in electroplate, i.e., covering an object in a sheet of copper) is my simple home-grown (server) provisioning system.
It grew out of a desire to integrate my provisioning system with my password manager of choice: [1Password](https://1password.com).
Specifically, it allows managing the disk encryption key, as well as SSH host keys.  
It also supports providing a disk encryption key from 1Password over SSH during boot.
Remote unlocking can be set up via my `remote-unlock` module.

It supports installing NixOS on a server via [nixos-anywhere](https://github.com/numtide/nixos-anywhere), updating a system via `nixos-rebuild` remotely and uploading a disk encryption key during boot for full disk encryption.

The CLI is available as the package `plate` in this flake.
To use it, include the `copper-plate` flake module and set the required options on `copperConfigurations.HOST.plate`.
::: tip
If you create your Flake with the `mkGleamingFlake` function provided here, the required module will be included automatically.
:::

::: details Usage without Flake Module
It is possible to use Plate without the Flake module by providing the expected output at `copperConfigurations.HOST.build.plate`.
However, the format of this output is not stable and this could break any time.
It is only recommended for advanced users.
:::

## Options

The options you may set for a given host are:

| Option Name | Required | Default | Description |
| ----------- | -------- | ------- | ----------- |
| `target`    | x        |         | The IP or hostname of the server that you want to configure. |
| `targetUser` |         | Current user | The username to use when connecting to the target for updates. This option can be overriden with the `--target-user` flag on the CLI. This user must be allowed to use `sudo` without interactive authentication. (Authentication via SSH keys is fine, however). If NixOS is already booted on the target system, it must be `root`. |
| `hostKey`   |          |         | A secret reference for the 1Password CLI that contains the private host key that you want to use for the server. This is optional, but recommended so the key stays persistent across re-installs. It will also automatically be added to your known hosts. |
|
| `hostKeyLocation` |    | `/etc/ssh/ssh_host_ed25519_key` | The path on the target system that the private key should be saved to. You may want to change this if you use a different key type or use impermanence on NixOS. |
| `diskEncryptionKey` |  |         | If you want to use Full Disk Encryption, this is a secret reference for the 1Password CLI for the passphrase to use for disk encryption. |
| `initrdPublicKey` |    |         | If using Full Disk Encryption and remote unlocking, this is the public host key used by SSH in the initrd. The private key is not deployed by Plate, but should be handled through other means. For example via Agenix or sops-nix. This Flake provides the [Copper Mage](/features/mage) abstraction to more easily integrate with agenix.

## CLI

Then, the operations supported by the `plate` CLI are as follows:

* `provision <flake-ref>#<host>` to set up NixOS on a server using nixos-anywhere.
* `update <flake-ref>#<host>` to build a new system configuration and deploy it on the host.
* `unlock <flake-ref>#<host>` to send the disk encryption key during boot.

`provision` accepts the following CLI switches:

* `--build-on-remote` to build all packages on the host to-be-provisioned
* `--port` to use a different port for the initial SSH connection
* `--target-user` to connect to a given user for the initial SSH connection

`update` accepts the following CLI switches:

* `--build-on-remote` to build all packages on the host to-be-updated
* `--test` to update the configuration, but revert to the prior one on reboot

`unlock` accepts the following CLI switches:

* `--ssh-only` to be dropped into the initrd shell rather than sending the unlock command

Additionally, once you use the above `<flake-ref>#<host>` at least once for a particular hostname, you can subsequently use just `<host>`, the Flake reference will be remembered.

## Plate Bake

Plate supports installing systems not just over SSH, but also via a custom install ISO.
It is configured by the same options and supports many cool features, such as

* generating Secure Boot keys if needed,
* securely deploying secrets,
* copying your Flake to the target system,
* including the generated hardware config in the built system, and
* installing standalone Home-Manager configurations.

This functionality is distributed as a seperate sub-command in the `plate-bake` package.
It accepts two named arguments:

* `--installer <flake-ref>` the system that the installer itself should boot into. You should probably use one of the base images from nixpkgs.
* `--target <flake-ref>` the system image that you actually want to install.

Plate Bake will generate in install ISO.
You may be asked for an encryption password that protects any secrets you want to deploy on your PC.
Plate Bake will not force you to use a secure password, but beware that your secrets are only as safe as the password you choose.

Once you have booted into the image, you want to run `sudo plate-install` in a terminal.
You will be guided through the installation.

## Limitations

If your configuration uses [IFD](https://nixos.org/manual/nix/stable/language/import-from-derivation), `--build-on-remote` will not work fully as you may expect.
Particularly, any derivations that are imported from may be build on your system or one of your configured builders.
