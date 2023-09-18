# Gleaming Glacier — Copper's Dotfiles

<p style="text-align: center; font-style: italic;">
  <img src="./logo.png" alt="The logo for this flake. A chunk of copper in the clearing of the woods, being covered by falling snow." style="display: block; max-width: 1024px; width: 100%; margin: 0 auto;">
  <span style="font-style: italic;">A chunk of copper being covered by snow flakes.</span>
</p>

These are my dotfiles, i.e., the configurations for my systems and tools, structured as a Nix flake, which makes them easy to install and reproduce.
> There are many like it, but these ones are mine.

This README is fairly long and contains a lot of information, a lot of which you probably don't need.
This overview should help you find what you need, in addition, links to other relevant sections are scattered throughout this README.

- [Gleaming Glacier — Copper's Dotfiles](#gleaming-glacier--coppers-dotfiles)
  - [Who is this for?](#who-is-this-for)
  - [Showcase](#showcase)
  - [Getting Started](#getting-started)
    - [Home-Manager](#home-manager)
    - [Nix-Darwin](#nix-darwin)
    - [NixOS](#nixos)
  - [Advanced Usage](#advanced-usage)
    - [Yoink bits and pieces](#yoink-bits-and-pieces)
    - [Create your own Flake and reference mine](#create-your-own-flake-and-reference-mine)
    - [Fork my Flake](#fork-my-flake)
  - [Flake Outptuts \& Structure](#flake-outptuts--structure)
    - [Packages](#packages)
    - [Overlays](#overlays)
    - [Apps](#apps)
    - [NixOS Modules](#nixos-modules)
      - [Features](#features)
    - [Home-Manager Modules](#home-manager-modules)
      - [Features](#features-1)
    - [nix-darwin Modules](#nix-darwin-modules)
      - [Features](#features-2)
    - [Common Modules](#common-modules)
    - [Host Configurations](#host-configurations)
    - [User Configurations](#user-configurations)
    - [Templates](#templates)
  - [Copper Plate](#copper-plate)
  - [FAQ](#faq)
    - [What is Nix?](#what-is-nix)
    - [Should I use Nix?](#should-i-use-nix)
    - [I've heard Flakes are experimental, are they safe to rely on?](#ive-heard-flakes-are-experimental-are-they-safe-to-rely-on)
    - [How do I install Nix?](#how-do-i-install-nix)
    - [Nix complains a file is not found or that there is no host/user configuraiton of a given name, but it's clearly there!](#nix-complains-a-file-is-not-found-or-that-there-is-no-hostuser-configuraiton-of-a-given-name-but-its-clearly-there)
    - [Isn't this totally overkill?](#isnt-this-totally-overkill)
  - [Commit Style](#commit-style)
  - [Versioning](#versioning)
  - [Contributing](#contributing)
  - [License](#license)
  - [Credits and Resources](#credits-and-resources)
    - [Nix Documentation](#nix-documentation)

## Who is this for?

Primarily, these are my own personal configurations for my devices set up to my liking.
However, this configuration is designed to be modular and contains parts that may be useful to you!
Or, you might just want to peruse the flake to get some inpiration for your own.

However, I believe that parts of my configurations may be useful for others, so this flake is structured so that you can easily fork it or even consume it in your own flake!
In fact, I do this myself for the configurations of my machines at work!

## Showcase

These dotfiles configure a variety of hosts, including:

macOS with
* The Yabai tiling window manager
* A Sketchybar top bar
* skhd for keyboard-based control of the above
* iTerm2
* The Neo2 keyboard layout

A NixOS server system with
* Full Disk Encryption
* Remote unlocking during boot
* Root on ZFS
* Automatic Disk partitioning
* Impermanence
* Secret management

A Fish environment with
* Starship
* fzf.fish, autopair.fish
* Catppuccin theme
* Delta & Lazygit
* GitHub Copilot
* more that I'm definitely forgetting

Screenshots are coming soon!

## Getting Started

If you don't yet use Nix to manage your dotfiles or system, you can follow these instructions to get started with your own config based on mine.
Note that these instructions are opinionated and represent my recommendations.
However, none of the information in this section is unique and you may also choose to head to the [Advanced Usage](#advanced-usage) section.

Nix can be used on either Linux or macOS.
Windows is *not* supported, though you may install Nix in WSL2, which is a virtual machine running Linux.
Make sure `curl` and `git` are available on your system and your Git `user.name` and `user.email` are configured
Then, install Nix and create a new Flake by running

```
bash <(curl https://raw.githubusercontent.com/Cu3PO42/gleaming-glacier/master/scripts/install.sh) --template
```

You may be prompted for authentication to proceed with the installation.
You must provide it or the process will fail.

At this point, you have your own repository in `~/dotfiles` or wherever else you specified that contains my template and can follow any of the following sections.
If you decide to stick with the base provided by my dotfiles, it would be highly appreciated if you'd leave a star.

### Home-Manager

Before creating a configuration, please make sure your `hostname` is stable since Home-Manager relies on it to identify your user configuration.
This can be set either through a NixOS config or using `nix-darwin`.
Don't worry if you don't plan to use either: you can still change your hostname to whatever you want.
The exact method will vary based on your system, but the most common ones are handled by an integrated script: run `nix run .#set-hostname <hostname>`.

You may now create a user configuration by running in the directory of your dotfiles:

```
nix run .#generate -- user
```

This creates a simple config enabling only my CLI and Fish shell settings, you are free to customize it further, either by activating more features, see [Home-Manager Features](#features), or by setting any number of other settings, see the [Home-Manager manual](https://nix-community.github.io/home-manager/).
You can also take a look at my [`users`](./users) folder to see my configurations.

Then you can run

```
nix run .#bootstrap -- --user
```

to activate your configuration for the very first time.
You may get an error that some files would be overwritten.
In that case my configuration tries to configure some tool you have manually configured before.
Either delete your own configs if you don't care about them or integrate them into your user profile and rerun the command above.

In the future you can run `home-manager switch --flake ~/dotfiles` to activate a new configuration.

Note that this configures Fish shell, but does not make it your default shell.
If you want to do that on a system that is neither NixOS nor macOS managed through nix-darwin, you need to run

```
sudo bash -c "echo $(which fish) >> /etc/shells"
chsh -s $(which fish) $(whoami)`.
```

> **Note**
> Be sure to push your local repository to the Git host of your choice!

### Nix-Darwin

To create a system configuration for a new Mac, you can run

```
nix run .#generate -- darwin [--host <hostname>]
```
If you do not specify a hostname, the current hostname will be assumed.
> **Warning**
> If you have not manually set a hostname, it may change at any time and break your configuration!

This creates a simple config enabling only basic CLI features, you are free to customize it further, either by activating more features, see [nix-darwin Features](#features-2), or by setting any number of other settings, see the [nix-darwin manual](https://daiderd.com/nix-darwin/manual/index.html).
You can also take a look at my [`hosts/darwin`](./hosts/darwin) folder to see my configurations.

Then you can run

```
nix run .#bootstrap -- --host [--hostname <hostname>]
```

to activate your configuration for the very first time.

If you have manually specified a hostname above, you need to specify it here as well.

After this setup you should reboot.

### NixOS

You can create a configuraiton for a new NixOS host by placing a NixOS `configuration.nix`-like file in `hosts/nixos/<hostname>.nix`.
The exact method by which you install or activate this configuration depends on how you want to use it.
If you'd like to deploy NixOS to a new server, you may refer to my deployment scripts [Copper Plate](#copper-plate).

I am intentionally not providing more detailed information here, because I advise against deploying NixOS without having a decently strong grip on it.

## Advanced Usage

Depending on your goals, there are various ways in which you might make use of my dotfiles.

1. If you don't use Nix at all or feel that my structure is massively overkill, you might just want to copy some files over to your own repository. The `config` folder includes configuration files that can be deployed independently of Nix.
2. You can fork this flake and integrate your system and home configurations directly.
3. You can use my Flake as an input in your own, either to just use some packages or modules, or even to use my infrastructure to directly set up systems.

If you're interested in setting up your own flake, but are overwhelmed with all of the options and possibilities, maybe check out [Getting Started](#getting-started).
That section is a more guided experience.

### Yoink bits and pieces

You are more than welcome to extract some parts of my configuration and integrate it into your own directly.
Please see the [Structure](#flake-outputs--structure) section to find what you need and take a look at the [License](#license).

### Create your own Flake and reference mine

If you'd like to create your own system configurations based on mine, the easiest way to do that is to use my Flake template.
You may either see the [Getting Started](#getting-started) section, or if you're already comfortable with Nix, you can run `nix flake init --template github:Cu3PO42/gleaming-glacier#system`.
The Flake template comes with [its own README](./templates/system/README.md) that helps you get started.

If you already have a Flake and only want to import some of my modules or packages, you can simply add my Flake as an input.
My outputs follow standard conventions, so you may find my modules is `nixosModules`, `darwinModules` and `homeModules`.
You may also be interested in using my functions that load configurations from a folder:
simply use the `load{Nixos,Darwin,Home}` functions from my `lib` export.
See the [system template](./templates/system/) for an example on how that works.

The outputs of this Flake are documented in the [Structure](#flake-outputs--structure) section.

> **Warning**
> **Advanced Users only**: Instead of importing my Flake from GitHub, you may also clone the repository to your drive and reference it via an absolute path.
> This approach is recommended only for fast iteration.
> If you decide to do that, you may also want to symlink config files instead of copying them so they can be modified without a new generation.
> If you want that, simply add `copper.file.symlink.enable = true;` to your config and set `copper.file.symlink.base` to the path to which you cloned the flake.
> Unfortunately, due to the pure nature of Flakes, it is impossible to determine the current path from within.

### Fork my Flake

You may simply fork my flake and replace my configs with your own.
For most usecases, I would recommend [using my flake as an input to your own](#use-my-flake-as-an-input-in-your-own) instead, since that allows you to more easily incorporate improvements from my flake.

For advanced users desiring strong customization, forking may still be preferable.
However, if you go ahead with this route, you probably want to remove my system and user configurations before adding your own.
In particular, these are the files in the `hosts` and `users` subdirectories.
Take a look at the [Structure section](#flake-outputs--structure) for more information on how these filse are structured.

I would love if you choose to contribute some of your improvements back upstream, see the [Contributing](#contributing) section.

## Flake Outptuts & Structure

This flake follows standard conventions for its output shema.
The following is an overview of the top-level attributes and how they map to the file structure of this flake.

* `packages.${system}`: any packages used by my configuration; constructed from the `packages/` subfolder
* `overlays`: nixpkgs overlays imported from `overlays/`
* `apps`: additional tools that make interacting with this flake easier; constructed from `apps/`
* `nixosModules`: modules used by my NiXOS configurations
  * generic modules constructed from `modules/nixos/` and `modules/common/`
  * [Feature Modules](#feature-modules) constructed from `features/nixos/` with names prefixed by `feature/`
* `homeModules`: modules used by my Home-Manager configurations
  * generic modules constructed from `modules/home/` and `modules/common/`
  * [Feature Modules](#feature-modules) constructed from `features/home/` with names prefixed by `feature/`
* `darwinModules`: modules used by my Home-Manager configurations
  * generic modules constructed from `modules/darwin/` and `modules/common/`
  * [Feature Modules](#feature-modules) constructed from `features/darwin/` with names prefixed by `feature/`
* `nixosConfigurations`: NixOS host definitions constructed from `hosts/nixos/`
* `homeConfigurations`: Home-Manager user configurations constructed from `users/`
* `darwinConfigurations`: Nix-Darwin host definitions constructed from `hosts/darwin/`
* `templates`: Flake templates imported from `templates/`
* `lib`: contains some utility functions; imported from `lib/`

The members of these top-level attributes are documented seperately in the following sections.
Whereever I have used the term *constructed* above, a utility function is used to (recursively) import all `.nix` files or folders with a `default.nix` into an attribute set where the name is the file path.
While this deviates from standard Nix conventions, I find it makes the flake much more maintainable since it reduces the number of places I need to touch for a given change.

Beyond files that immediately contribute to the flake outputs above, this repository also contains the following folders:
* `config/` contains configuration files for various tools. I install them via my Home-Manager configurations, but you could also use them directly
* `scripts/` contains scripts that make it easier to interact with this flake. They are mostly wrapped as `apps` and accessible via Nix.

> **Note**
> <a id="feature-modules"></a>
> The majority of my configurations are seperated into what I call *feature modules*.
> While they can be toggled on and off and may occasionally have their own options, they are fundamentally my configurations and not for generic use.
> They are a great option if you simply wish to copy my configuration, however.
>
> To enable a feature module, set `copper.feature.<name>.enable = true`.
> Unless enabled they have no effect, so are safe to include by default.
> For convenience (and legacy reasons), there is also an option `copper.features` that can be set to a list of feature names that will be enabled.

### Packages

My Flake exports the following packages, which are mostly external programs I have packaged for Nix:

* `plate`: my tiny provisioning script, see [Copper Plate](#copper-plate)
* `generate`: a tiny templating script to create new user and host configs
* `rga-fzf`: a simple wrapper around `ripgrap-all` and `fzf` that allows grepping for a certain string and then fuzzy filtering of the results
* `ifstat`: a tool to provide statistics about network activity on macOS
* `ical-buddy`: a tool to interact with the calendar database on macOS
* `sketchybar-helper`: a part of FelixKratz' [Sketchybar](https://github.com/FelixKratz/SketchyBar) config, which I am also using. It updates CPU usage for my macOS status bar
* `liga-sfmono-nerdfont`: a variant of the San Francisco Mono font with ligarutes and Nerd Font icons
* `sketchybar-app-font`: a font that has icons for various macOS applications

### Overlays

I also have overlays that make other features of this Flake easier to use:

* `additions`: simply adds all my packages into the package set
* `flake-inputs`: adds packages from all Flake inputs into the package set

### Apps

* `bootstrap`: a wrapper srcipt used to activate configurations for the very first time. See [Getting Started](#getting-started) for usage examples
* `generate`: templates a new host or user configurations. Set [Getting Started](#getting-started) for its usage.
* `set-hostname`: sets the hostname of the current system. Abstracts over various systems, such as macOS, Linux with systemd and Linux without systemd

### NixOS Modules

* `plate`: adds support for my provisioning system to a host. See the [Copper Plate](#copper-plate) section for more documentation

#### Features

* `base`: this mostly sets up Nix settings and installs some basic packages I want on every system
* `hetzner-server`: system-specific settings generic to all Hetzner Cloud servers
* `home-manager`: sets up the NixOS Home-Manager module to be compatible with my configs
* `hyprland`: installs Hyprland
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

* `lunarvim`: an attempt to package [LunarVim](https://www.lunarvim.org), a NeoVim distribution, for NixOS by replicating the setup created by its installer script
* `copper-file`: an abstraction layer used by my own configs for linking or copying config files. By default, files are linked from the Nix Store, making it easier to switch back to previous generations, but they can also be linked to the location of the repository by setting
```
copper.file.symlink = {
  enable = true;
  base = "/path/to/repo";
};
```

#### Features

* `catpuccin`: configures the Catppuccin theme for a lot of applications
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

* `copper-features`: a trivial helper that allows setting `copper.features = [...]` instead of a number of `copper.feature.<name>.enable = true`. This exists mainly for legacy reasons.
* `copper-patches`: a helper to apply patches to `nixpkgs`. By setting `copper.patches.<pkg>` to any list of patch files, an overlay is created that uses `overrideAttrs` on `<pkg>` to add the specified patches

### Host Configurations

NixOS and macOS hosts are configured in `hosts/nixos/` and `hosts/darwin/` respectively.
The principles for both are the same, however:
Any file named `hostname.nix` or folder `hostname` with a `default.nix` provides the configuration for a host with the given `hostname`.
The contents of the file should be a standard NixOS/nix-darwin module as would be stored in a `configuration.nix`.

`networking.hostname` is automatically set based on the file name.
Additionally, all my NixOS/nix-darwin modules are injected and my `base` feature is activated via `copper.feature.base.enable = true`.

### User Configurations

Home-Manager configurations are stored in `users/`.
Any file named `user@hostname.nix` or folder `user@hostname` with a `default.nix` provides the configuration for user `user` on a host named `hostname`.
The contents of the file should be an attribute set:
```nix
{
  # List of Home-Manager modules to apply
  modules = [];
  # Architecture of the host system. The given value aarch64-linux is just an
  # example. Adjust it for your usecase
  system = "aarch64-linux";
}
```

`home.userName` is automatically set based on the file name.
Additionally, all my Home-Manager modules are injected and by `standaloneBase` feature is activated.

### Templates

* `system`: A Flake that can be used to define your own system and user configs based on the frameworks introduced in this flake.

I plan to also keep templates for the development of projects in various languages here.

## Copper Plate

Copper-Plate (as in electroplate, i.e., covering an object in a sheet of copper) is my simple home-grown (server) provisioning system.
It supports installing NixOS on a server via [nixos-anywhere](https://github.com/numtide/nixos-anywhere), updating a system via `nixos-rebuild` remotely and uploading a disk encryption key during boot for full disk encryption.

It is available as the package `plate` in this flake.
To use it, you must use the `copper-plate` NixOS module and add the `copper.plate` configuration options with the following sub-keys:

* `target`: The IP or hostname of the server that you want to configure.
* `targetUser`: The username to use when connecting to the target for updates. This does not affect the account to use for provisioning, which will always be `root`. This user must be allowed to use `sudo` without interactive authentication. (Authentication via SSH keys is fine, however).
* `hostKey`: A secret reference for the 1Password CLI that contains the private host key that you want to use for the server. This is optional, but recommended so the key stays persistent across re-installs. It will also automatically be added to your known hosts.
* `hostKeyLocation`: The path on the target system that the private key should be saved to. By default this is `/etc/ssh/ssh_host_ed25519_key`, but you may want to change this if you use a different key type or use impermanence on NixOS.
* `diskEncryptionKey`: If you want to use Full Disk Encryption, this is a secret reference for the 1Password CLI for the passphrase to use for disk encryption.
* `initrdPublicKey`: If using Full Disk Encryption and remote unlocking, this is the public host key used by SSH in the initrd. The private key is not deployed by Plate, but should be handled through other means. (For example as a secret using agenix or sops-nix.) Note that my `remote-unlock` module makes this easy: just set
```
copper.feature.remote-unlock = {
  enable = true;
  initrdHostKeySecret = ./path/to/your/key.age;
};
```
and deployment of the key is handled automatically.

Then, the operations supported by the `plate` CLI are as follows:

* `provision <flake-ref>#<host>` to set up NixOS on a server using nixos-anywhere.
* `update <flake-ref>#<host>` to build a new system configuration and deploy it on the host.
* `unlock <flake-ref>#<host>` to send the disk encryption key during boot.

Additionally, once you use the above `<flake-ref>#<host>` at least once for a particular hostname, you can subsequently use just `<host>`, the Flake reference will be remembered.

## FAQ

Overview:
* [What is Nix?](#what-is-nix)
* [Should I use Nix?](#should-i-use-nix)
* [I've heard Flakes are experimental, are they safe to rely on?](#ive-heard-flakes-are-experimental-are-they-safe-to-rely-on)
* [How do I install Nix?](#how-do-i-install-nix)
* [Nix complains a file is not found or that there is no host/user configuraiton of a given name, but it's clearly there!](#nix-complains-a-file-is-not-found-or-that-there-is-no-hostuser-configuraiton-of-a-given-name-but-its-clearly-there)
* [Isn't this totally overkill?](#isnt-this-totally-overkill)

### What is Nix?

The term Nix is somewhat overloaded, in a programming language sense.
It refers to the language Nix, as well as the eponymous package manager that uses the language for configuration.
Additionally, there is the package repository nixpkgs mainly used by the above package manager, as well as a Linux distribution NixOS built on that package manager.
nixpkgs is the largest package repository among any of the widely used Linux package repositories, larger even than the AUR.

Nix — the language — is a functional, fully-featured programming language.
Nix — the package manager — has the goal of fully reproducible builds.
This means that if something works once, it will continue to work forever on any machine of the same architecture.
While this is an excellent property in general, it comes in particularly handy to manage system configurations.
In combination with the purity of the Nix language, it is nearly impossible to miss any dependencies, so deployments will always "just work".

### Should I use Nix?

Nix is an excellent tool that can save you large amounts of work.
However, it works best when it manages every part of your system it can get its hands on.
This means that once you start using it, you will want to make further modifications directly in the Nix config.
In other words, you should only employ it if you're willing to learn the language and conventions of the ecosystem (or you're happy to just use my or someone else's configuration 1:1).

If you'd like to get started with Nix, you can see the [Documantation section](#nix-documentation) for some references.

### I've heard Flakes are experimental, are they safe to rely on?

I think so, yes.
While Flakes are experimental, they are available in stable versions of Nix and widely used by the community because they solve a large number of pain points.
In particular, they provide a declarative way of specifying and composing dependencies without relying on system state.
They also unify many commands and offer better structure.

This widespread adoption is recognized by the project, which has just recently adopted [RFC 0136](https://github.com/NixOS/rfcs/pull/136) with the goal of eventually stabilizing Flakes and managing breaking changes.

### How do I install Nix?

To get started with using this repository, you will need a working installation of Nix.
Depending on your environment, I recommend different options to get started.
In principle, Nix can be installed for a single-user or system-wide.
I recommend the latter option wherever possible.
However, a multi-user installation requires systemd on Linux, which may not always be available, especially in WSL2.

If you are happy to trust my recommendations, you can use my `install.sh` script if you have checked out this repository, or directly via curl:
```
bash <(curl https://raw.githubusercontent.com/Cu3PO42/gleaming-glacier/master/scripts/install.sh)
```
Otherwise, please follow these questions for my recommendation on how to install Nix.

* Are you on Linux or macOS?
  * If you are on Linux, are you in an environment in which systemd is available? If you don't know the answer to this question, you can run `ps -p 1 -o comm=`. If the output is systemd, you are running it, otherwise you probably aren't. You probbaly do use systemd if you installed any of the standard Linux distributions, unless you are using WSL2, in which case you do not have systemd by default.
    * If you use systemd, I recommend the [Determinate Systems Nix Installer](https://github.com/DeterminateSystems/nix-installer). Simply run
      ```
      curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
      ```
    * If you do not use systemd, I recommend a single-user installation using the [official Nix installer](https://nixos.org/download). Run
      ```
      sh <(curl -L https://nixos.org/nix/install) --no-daemon
      ```
      You will also want to configure support for Flakes. You can do that by running
      ```
      mkdir -p ~/.config/nix
      echo "experimental-features = flakes nix-command" > ~/.config/nix/nix.conf
      ```
  * If you use macOS, do you intend to use `nix-darwin` to manage your system, or are you only interested in other features, such as Home Manager?
    * If you want to use `nix-darwin`, I recommend a multi-user installation using the [official Nix installer](https://nixos.org/download). Run
      ```
      sh <(curl -L https://nixos.org/nix/install) --daemon
      ```
      You will also want to configure support for Flakes. You can do that by running
      ```
      mkdir -p ~/.config/nix
      echo "experimental-features = flakes nix-command" > ~/.config/nix/nix.conf
      ```
    * If you do not intend to use `nix-darwin`, I recommend a multi-user installation using the [Determinate Systems Nix Installer](https://github.com/DeterminateSystems/nix-installer). Simply run
      ```
      curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
      ```

### Nix complains a file is not found or that there is no host/user configuraiton of a given name, but it's clearly there!

Every file in a Flake must be added to the Git index, otherwise it is entirely ignored during evaluation.
If you have just created a file, this may be the reason that it is not found.
Just `git add` it!

Note that it is not necessary for all your changes to a file to be added, it is sufficient to add it once.

### Isn't this totally overkill?

Maybe. But having your systems be totally documented and reproducible is increadibly satisfying and freeing even. You should [try it](#getting-started).

## Commit Style

All changes should, ideally, be split into atomic commits, i.e., the smallest commits such that each commit makes sense on its own.
Additionally, commit messages should observe the follownig format:

```
$type($area): $short

$body

$footer
```

* `$type` classifies the changes made. Possible values are `feat` for a new feature, `fix` for a bugfix, `chore` for changes such as dependency upgrades or refactorings and `docs` for purely documentation updates.
* `$area` describes the subsystem of the Flake that is affected. Possible values are `home` for home-manager configs, `darwin` for macOS, `nixos` for NixOS config, `infra` for templating, deployment and such, as well as `pkg` for new packages. If nothing else applies or the changes span multiple subsystems, `*` should be used.
* `$short` roughly describes the changes made. It should be implicitly read as "When applied, this commit will `$short`."
* `$body` is a much more detailed description of the changes, including why they were mande and what other affects they may have
* `$footer` contains messages such as `Reverts commit xyz` or `Fixes #123`.

## Versioning

At this time, my Flake is still rapidly changing.
I am intentionally not versioning it and make no promises about the stability of any particular API.
That said, I'll try not to break things too much.

Still, if you rely on my Flake, be sure to use a particular version and be prepared to make some changes when upgrading to a new commit.

## Contributing

Contributions are welcome!
You may raise an issue if you notice a bug or - even better - send a Pull Request fixing it.
I'm also open to adding new features, in particular improvements to the documentation, templating, deployment or other 'meta' systems.
However, this is still my personal flake that I'm maintaining for my own use primarily.
If you add a feature that I have no use for and don't believe is worth the maintenance burden to me, I might not accept your PR.
So please, do open an issue to discuss before you invest significant amounts of work.

Even if you can't contribute any fixes or features, I'd still greatly appreciate ifi you'd leave a star on the repository.

By contributing, you agree to license your work under the terms laid out in the [License](#license) section below.

## License

Unless otherwise noted, all code in this repository is available under the terms of the GPLv3 or, at your option, by any later version of the GPL released by the Free Software Foundation and approved by [@Cu3PO42](https://github.com/Cu3PO42).
By contributing to this repository, you also agree to license your code under these terms.

This repository also contains bits and pieces of configuration from other people's dotfiles that they have shared on GitHub.
Such code is marked either by a comment in the file itself or an accompanying `LICENSE` file, describing the license that the relevant code is available under.

I do include this code here, because I believe it is in the spirit of these dotfile repositories to share and learn from each other.
(And - legally - the GitHub Terms of Service permit other users to share code that was released as part of a public repository on GitHub.)
If, however, you are the author or otherwise have claims on one such piece of code contained in this repository, please contact me and I will remove it.

## Credits and Resources

These dotfiles reuse parts of various others' configurations and inspired by many more.
In particular, configuration from the following repositories was used:

* [FelixKratz' dotfiles](https://github.com/FelixKratz/dotfiles/) from which I initially copied the skhd, yabai and SketchyBar config, available under the terms of GPLv3
* [ghostx31's dotfiles](https://github.com/ghostx31/dotfiles) whose Wezterm config I am using
* [hunterliao29's Apple Music plugin for sketchybar](https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-4406700)
* [khaneliman's dotfiles](https://github.com/khaneliman/dotfiles) from where I took some sketchybar configuration
* [yuanw's nix-home](https://github.com/yuanw/nix-home) which is the origin of my icalBuddy derivation
* [EphraimSiegfried's Calendar plugin for Sketchybar](https://github.com/FelixKratz/SketchyBar/discussions/12#discussioncomment-4730516)

Additionally, I learned a lot from these repositories, listed in no particular order:

* [Misterio77's Flake](https://github.com/Misterio77/nix-config)
* [MatthiasBenaets's Flake](https://github.com/MatthiasBenaets/nixos-config/tree/master)
* [Pimey's Flake](https://github.com/pimeys/nixos)
* [alodborrero's templates](https://github.com/aldoborrero/templates/tree/main/templates/blog/nix/setting-up-machines-nix-style)
* [alexghr's Flake](https://github.com/alexghr/nix)

If you believe you were missed in the list above, please let me know.

### Nix Documentation

If you are unfamiliar with Nix, I recommend the following resources to get a feel for the ecosystem:

* [**Overview of the Nix language**](https://nixos.wiki/wiki/Overview_of_the_Nix_Language) to learn the language seperate from its application of package management
* [**Zero to Nix**](https://zero-to-nix.com) for a rough overview of "modern" Nix
* [**Nix Pills**](https://nixos.org/guides/nix-pills/) a tried and true resource for a deeper dive into various aspects of the ecosystem. However, this still refers to how things were done before Flakes.
* [**Nix from first principles**](https://tonyfinn.com/blog/nix-from-first-principles-flake-edition/) for a series of blog posts that touch a bit on everything
* [**This meta list of tutorials**](https://www.reddit.com/r/NixOS/comments/v2xpjm/big_list_of_flakes_tutorials/)

Additionally, you will want to reference the manuals for all NixOS, Home-Manager, and nix-darwin configuration options if you want to modify any of these configs:

* [NixOS](https://nixos.org/manual/nixos/stable/)
* [Home-Manager](https://nix-community.github.io/home-manager/)
* [nix-darwin](https://daiderd.com/nix-darwin/manual/index.html)