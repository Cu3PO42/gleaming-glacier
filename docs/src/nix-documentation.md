---
title: Nix Documentation
---

# Nix Documentation

Nix is an extremely powerful tool, but unfortunately its documentation is not quite what it could be.
In this document, I attempt to motivate the need for Nix and disambiguate the word before referring you to [additional material](#documentation).

# Getting Started with Nix – The Guide I Wish I had

When I first heard about Nix, I immediately loved the idea, but was scared by the complexities it seemed to bring.
Years later, confronted with yet another case of "It works on my machine!" I decided to give Nix a serious try.

## What is Nix?

Nix is many things.
Among those it is a package manager for \*NIX systems, particularly Linux and macOS.
It is similar to `apt` on Debian or Ubuntu, `dnf` on Fedora, `zypper` on SUSE, or `pacman` on Arch.
As such it allows you to install both programs and libraries for use by other programs or for development on your machine.
However, it is different from the above programs in that it is designed to run on any Linux distributions, possibly alongside your main package manager!
It achieves this by isolating everything to its own directory in `/nix/store` where every version of every package has its own directory and referring to everything by these absolute paths.

## Why Nix?

Okay, but `apt` works fine, I hear you say.
And it does, but there are several key advantages to using Nix:

* Much larger package repository (larger even than the AUR)
* Per-user package installations
* Per-project package installations
* Systems are fully reproducible from a declarative config

## Disambiguation: Nix Language, Nixpkgs, NixOS

The term Nix may – depending on the context – refer to either the Nix language, Nix the package manager, nixpkgs, or, on occasion, even NixOS.
While these are all tightly related, they are not the same thing and understanding the differences is important to grasping the ecosystem.

The Nix language is a programming language of its own right.
It is functional, lazy, and dynamically strongly typed.
While it could theoretically support many applications, the only uses I am aware of are in the Nix ecosystem itself.
The Nix package manager uses the Nix language to create definitions for its packages.
Using a fully featured programming language rather than a small configuration language such as TOML or YAML allows for great flexibility, but also incurs complexity.
Nixpkgs is the official repository of package definitions used by the Nix package manager and written in the Nix language.
Finally, NixOS is an entire Linux distribution based around the concepts of the Nix package manager.
It features Nix as its only package manager and features a system where a system can be fully recreated from its declaration.

# Documentation

To learn about the Nix language, the package manager, and even NixOS, I refer you to the following list of documents:

* [**Nix.dev**](https://nix.dev) the official, central location for all kinds of documentation
* [**Overview of the Nix language**](https://nixos.wiki/wiki/Overview_of_the_Nix_Language) to learn the language seperate from its application of package management
* [**Zero to Nix**](https://zero-to-nix.com) for a rough overview of "modern" Nix
* [**Nix Pills**](https://nixos.org/guides/nix-pills/) a tried and true resource for a deeper dive into various aspects of the ecosystem. However, this still refers to how things were done before Flakes.
* [**Nix from first principles**](https://tonyfinn.com/blog/nix-from-first-principles-flake-edition/) for a series of blog posts that touch a bit on everything
* [**This meta list of tutorials**](https://www.reddit.com/r/NixOS/comments/v2xpjm/big_list_of_flakes_tutorials/)

Additionally, you will want to reference the manuals for all NixOS, Home-Manager, and nix-darwin configuration options if you want to modify any of these configs:

* [NixOS](https://nixos.org/manual/nixos/stable/)
* [Home-Manager](https://nix-community.github.io/home-manager/)
* [nix-darwin](https://daiderd.com/nix-darwin/manual/index.html)