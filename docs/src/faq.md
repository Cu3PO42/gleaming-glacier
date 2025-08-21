---
title: FAQ
outline: 3
---

# FAQ

## Regarding This Flake

### Gleaming vs. Copper

The contents of this Flake are grouped into two namespaces: `gleaming` and `copper`.
The former refers to features of the Flake meta-framework that are independent of my particular configuration and features.
The latter concerns my configuration, which you can re-use and adjust to your taste, but can also omit entirely.

## Nix

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

## NixOS

### Should I use NixOS?

NixOS is fundamentally different from many classic Linux distributions in how it is used.
Instead of imperatively modifying state by installing packages and changing config files, you write a monolithic declarative configuration for your entire system and build that.
That means that it is highly reproducible, but also fundamentally different and requires significant adjustment.

If you're just getting started, I would recommend you start with Home-Manager or stick to a VM.

