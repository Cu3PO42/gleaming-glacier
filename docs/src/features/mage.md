---
title: Copper Mage–Easier Agenix
---

# Copper Mage

[Agenix](https://github.com/ryantm/agenix) is a system to safely deploy secrets via Nix.
You should not include any secrets direcly since tat would put them into the Nix-store, which is world-readable on a given system.

Agenix encrypts your secrets to ensure they remain safe even if you upload your configuration to GitHub, as I have.
On the target system, a service runs that decrypts the secrets using a private key and gives access to only the users and groups that should have it.
Of course, to decrypt the secrets, the target system still needs a private key, which is in itself secret.
Conveniently, my [Plate](plate) system, can safely deploy that key for you!

Agenix is extremely flexible system, but in my opinion a bit clunky to use.
Thus, Mage was born.
It's a simple abstraction over Agenix with defaults that work for me and make it a breeze to use.

::: info
If these defaults don't work for all your use cases, please note that you can still use Agenix directly and set any supported options, even when Mage is used for some parts.
:::

### Setup

It assumes that you use a single key on your device to decrypt your secrets and that that key is stored in 1Password.
To use it, you must first create a file called `mage.nix` in the root of your Flake.
It must evaluate to a single object with the following properties:

| Key | Description |
| --- | ----------- |
| `ageRootKey.public` | The public key of your 'root key'. |
| `ageRootKey.private` | A 1Password secret reference to your private root key. |
| `opAccount` | The domain in which the 1Password account that contains your secret lives. This is useful or necessary if you are logged into multiple accounts, for example your personal and a business account. |

Then, for every host/configuration, you specify the following configuration options on your Flake's `copperConfig.HOST.mage` output.

| Key | Description |
| `secrets` | A folder that contains the secrets to deploy on this host. |
| `publicKey` | The public key of the host's secret decryption key. |

::: tip
If you use the [autoload module](/features/gleaming-autoload), you do not need to set this setting manually.
Instead, it will be picked up directly from your host definition.
:::

Right now, a directory for shared secrets is not supported, but it is planned.

### CLI

At this point you're ready to use the Mage CLI!
Invoke it as follows:
```sh
mage <operation> <flake>#<host> <secret>
```

Two operations are currently supported: `decrypt` and `edit`.
The first decrypts the specified secret and prints it to stdout, the latter opens your `$EDITOR` for the secret.
The `<flake>#<host>` reference works just like it would for `nixos-rebuild`.
Finally, `secret` is the name of the file the secret is stored in, in the secret directory specified for the host.

### Limitations

Today, only NixOS configurations are supported, but support for nix-darwin and Home-Manager is planned.

There is also not yet an easy system for sharing secrets between hosts.
Currently, I simply copy secrets between hosts.
A more elaborate system is planned for the future.

You can, of course, fall back to standard Agenix to go beyond these limitations.
