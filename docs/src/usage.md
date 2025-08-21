---
title: Usage
---

# Usage

So you want to replicate my setup?
Depending on your goals, there are various ways in which you might make use of my dotfiles.
They are explained in the following sections.

1. You can use my Flake as an input in your own, either to just use some packages or modules, or even to use my infrastructure to directly set up systems.
2. If you're interested in setting up your own flake, but are overwhelmed with all of the options and possibilities, maybe check out [Getting Started](#getting-started).  That section is a more guided experience.

* If you are already using Nix in some capacity to manage your systems, you can reference my Flake and include any modules that suit you. Please see the [Flake reference](/reference/flake) for included modules and packages.
* If you don't yet use Nix to manage your dotfiles or system, you can follow these instructions to get started with your own config based on mine.  Note that these instructions are opinionated and represent my recommendations.

## Usage without Nix

If you don't use Nix at all or feel that my structure is massively overkill, you might just want to copy some files over to your own repository.
The `config` folder includes configuration files that can (mostly) be deployed independently of Nix.
I say mostly because they may contain references to paths that would usually be populated by Nix.
Please note that many applications are configured via Nix and the actual config file is only generated as part of the build process. Unfortunately, you cannot simply copy such configuration from this repository if you don't plan to use Nix yourself.

## Copy-Paste with Nix

You are more than welcome to extract some parts of my configuration and integrate it into your own directly.
Please see the [Flake Reference](/reference/flake) section to find what you need and please respect the [License](https://github.com/Cu3PO42/gleaming-glacier/blob/master/LICENSE.md).

## Reference my Flake

If you already have a Flake and only want to import some of my modules or packages, you can simply add my Flake as an input.
My outputs follow standard conventions, so you may find my modules is `nixosModules`, `darwinModules` and `homeModules`.
The specific outputs are documented in the [Flake reference](/reference/flake).
You may also be interested in migrating to my autoloading framework.
See the [system template](https://github.com/Cu3PO42/gleaming-glacier/tree/master/templates/system/) for an example on how that works and also check the [Gleaming Autoload documentation](/features/gleaming-autoload).

The outputs of this Flake are documented in the [Structure](#flake-outputs--structure) section.

::: warning Advanced Users Only
Instead of importing my Flake from GitHub, you may also clone the repository to your drive and reference it via an absolute path.
This approach is recommended only for fast iteration.
If you decide to do that, you may also want to symlink config files instead of copying them so they can be modified without a new generation.
If you want that, simply add `copper.file.symlink.enable = true;` to your config and set `copper.file.symlink.base` to the path to which you cloned the flake.
Unfortunately, due to the pure nature of Flakes, it is impossible to determine the current path from within.
:::

## Getting Started from Scratch {#getting-started}

### Installing Nix

Nix can be used on either Linux or macOS.
Windows is *not* supported, though you may install Nix in WSL2, which is a virtual machine running Linux.
Make sure `curl` and `git` are available on your system.
Then you can run
```sh
bash <(curl https://raw.githubusercontent.com/Cu3PO42/gleaming-glacier/master/scripts/install.sh)
```
to install Nix according to my recommentations.

::: info
You may also proceed with the installation manually using either the [official installer](https://nixos.org/download/) or [DeterminateSystem's installer](https://zero-to-nix.com/start/install).

If you use the official installer, you must also manually configure Nix to enable the features `flakes` and `nix-command`.
:::

You may be prompted for authentication to proceed with the installation.
You must provide it or the process will fail.

## Create your own Flake

Make sure your Git `user.name` and `user.email` are configured.
Then, install Nix and create a new Flake by running

```sh
bash <(curl https://raw.githubusercontent.com/Cu3PO42/gleaming-glacier/master/scripts/install.sh) --template
```

At this point, you have your own repository in `~/dotfiles` or wherever else you specified that contains my template and can follow any of the following sections.

### Using my Template

Once Nix is installed, you can use
```sh
nix init --template github:Cu3PO42/gleaming-glacier#system
```
to initialize my template in the current directory.

I like storing my dotfiles in `~/dotfiles`, but the path is up to you.
You should then run
```sh
./welcome.sh
```
to configure some additional properties.


::: tip
Be sure to push your local repository to the Git host of your choice!
:::

### Home-Manager

If you want to manage multiple users on different systems that share the same user name, Home-Manager can use your hostname to differentiate these systems.
Doing so requires you to have a stable hostname, however.

This can be set either through a NixOS config or using `nix-darwin`.
Don't worry if you don't plan to use either: you can still change your hostname to whatever you want.

The exact method will vary based on your system, but the most common ones are handled by an integrated script: run `nix run github:Cu3PO42/gleaming-glacier#set-hostname <hostname>`.

You may now create a user configuration by running in the directory of your dotfiles:

```sh
nix run .#generate -- user [--single-system]
```

Pass `--single-system` if you do not want to use the hostname for disambiguation.

This creates a simple config enabling only my CLI and Fish shell settings, you are free to customize it further, either by activating more features, see [Home-Manager Features](/reference/flake#home-manager-modules), or by setting any number of other settings, see the [Home-Manager manual](https://nix-community.github.io/home-manager/).
You can also take a look at my [`users`](https://github.com/Cu3PO42/gleaming-glacier/tree/main/users) folder to see my configurations.

Then you can run

```sh
nix run .#bootstrap -- --user
```

to activate your configuration for the very first time.
You may get an error that some files would be overwritten.
In that case my configuration tries to configure some tool you have manually configured before.
Either delete your own configs if you don't care about them or integrate them into your user profile and rerun the command above.

In the future you can run `home-manager switch` to activate a new configuration.

::: warning
If you move your configuration, you will need to edit your configuration to include the new path.
You also need to run `nix run .#boostrap -- --user` again to make Home-Manager aware of the new path.
:::

Note that this configures Fish shell, but does not make it your default shell.
If you want to do that on a system that is neither NixOS nor macOS managed through nix-darwin, you need to run

```sh
sudo bash -c "echo $(which fish) >> /etc/shells"
chsh -s $(which fish) $(whoami)`.
```

::: warning
If you do not manage your shell through NixOS nor nix-darwin, but install it through Nix, you may need to update your `/etc/shells` every time you update.
:::

### Nix-Darwin

To create a system configuration for a new Mac, you can run

```sh
nix run .#generate -- darwin [--host <hostname>]
```
If you do not specify a hostname, the current hostname will be assumed.
::: warn
If you have not manually set a hostname, it may change at any time and break your configuration!
In that case, please choose one as part of the command above.
:::

This creates a simple config enabling only basic CLI features, you are free to customize it further, either by activating more features, see [nix-darwin Features](#features-2), or by setting any number of other settings, see the [nix-darwin manual](https://daiderd.com/nix-darwin/manual/index.html).

Then you can run

```sh
nix run .#bootstrap -- --darwin [--hostname <hostname>]
```

to activate your configuration for the very first time.

If you have manually specified a hostname above, you need to specify it here as well.

After this setup you should reboot.

### NixOS

::: warn
I strongly advise against deploying NixOS in any production workload without having a decently strong grip on it.
:::

To create a fresh NixOS configuration in the Gleaming framework, run
```sh
nix run .#generate -- nixos [--hostname <hostname>] [--local]
```

If you specify `--local`, the hardware configuration for the current system will be included and the current hostname will be used.
DO NOT simply install this configuration on your current (or any other) system.
Things will likely break if you don't make the necessary adjustments to your system.
If you already have a working configuration, you should integrate it into the freshly generated configuration.

Once you are happy with your configuration, you can deploy it as usual with `nixos-rebuild`.
Unfortunately, this is not yet a complete guide to NixOS, so I must refer you to [Nix documentation](/nix-documentation) for what exactly you need to do.

If you'd like to deploy NixOS to a new server, you may refer to my deployment scripts [Copper Plate](#copper-plate).
