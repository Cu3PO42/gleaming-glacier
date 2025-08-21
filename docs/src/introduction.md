---
title: Introduction
---

# Introduction

These used to be my dotfiles, i.e., the configurations for my systems and tools, structured as a Nix flake, which makes them easy to install and reproduce.
They still are, but they used to be, too!
Over time, however, my configuration has required many large features, which go beyond pure configuration and are useful on their own.

> These are my dotfiles, there are many like it, but these ones are mine.

My dotfiles now include a generic theming system for Linux desktops (and macOS, too!), a simple server provisioning tool, abstractions around many lower-level tools, and even a Flake meta-framework.
Please see the [highlights](/highlights)!

----------

This repository can be seperated into three primary components:
* The afore-mentioned Flake meta-framework (found in the `gleaming` namespace)
* A number of generic Nix modules and features
* My own personal configurations set up to my liking, based on my framework and using my features (found in the `copper` namespace).

In contrast to the framework and features, my configurations are not always desigined to be generic.
That means that if you have similar requirements as I, you may find them useful, but if yours are wildly different, you may not.
Supporting every possible use case is not a goal for my own configuration.
In any case, my configurations are highly modular, so you can pick and choose any parts that you like.
Or, you might just want to peruse the flake to get some inpiration for your own.

## Getting Started

To get started on using my configuration, please see the [Usage](/usage) page.