---
title: Copper Chroma
---

# Chroma

Copper Chroma is the theming system I have developed for my configurations.
It is supported on both Linux and macOS and is extensible to support many different UI frameworks and applications.
Its goal is to achieve a coherent look for the entire system while adhering to Nix philosophy, i.e., minimizing state and being highly reproducible.

It consists of a set of Home-Manager modules and an associated command-line tool to switch the active theme.

A Chroma theme is a collection of themes for all (or some) of the supported applications.

## Design Goals

Chroma aims to

* support as many applications as possible, and be easliy extensible to new ones,
* support fast theme switches,
* support hot reload of themes in currently running applications,
* support both Linux and macOS as much as possible,
* integrate easily into Home-Manager,
* be easily extensible and useable.

## Fundamentals

Chroma relies on configuring all applications to load theming settings from a centralized folder per theme.
This folder is then updated to switch themes.
Additional activation scripts are executed to support applications that require imperative configuration and to hot-load changes in already running applications.

## Layout on Disk

Chroma places its files under `$XDG_CONFIG_HOME/chroma` by default.
Under this folder, you wil find the following structure:
```
- active  # a symlink to one of the themes in 'themes'
- themes/
  - <name>  # a folder for each theme
    - activate  # Invokes the activation ticket for every application
    - reload  # Invokes the reload script for all applications
    - <application name>  # folder for each themed application
      - activate  # Contains any additional commands to set theming settings. Run in evrey session
      - reload  # Reloads the configuration files
      - <additional files>  # additional files determined by the theme
- themes.json  # a list of all available theme names
```

Wherever possible, Chroma configures its supported applications to include config files from the `$XDG_CONFIG_HOME/chroma/active/<application>` folder.
Additionally, the `reload` scripts instruct the application to reload its configuration files.
They are invoked whenver the theme is changed dynamically.

Some applications can't be fully themed using configuration files, for example GTK-based apps, which require dconf properties to be set.
For these, our activation scripts are not only run when the theme is switched, but also on every login.

## How to add support for new themes

Every application supported by Chroma is added in the same way: by a new Home-Manager module.
By convention, it accepts arguments in the `copper.chroma.<application>` namespace, one of which must be a boolean `enable` option.

To configure its integration into Chroma, it must set the `copper.chroma.applications.<application>` option.
Various sub-options are important:
* `activationCommand`: A function that determines the activation commands for the application for a concrete theme
* `reloadCommand`: The reload command, not as a function but as a static string
* `themeOptions`: This determines the options that are set on a theme for this application
* `themeConfig`: A function computing options that will be merged into every theme for this application. It is useful primarily for setting the file option.

Additionally, it should set options to include theme files from the active theme, but only if theming support for the application is enabled.
It may also set other necessary options.

## How to write a theme

A theme is an attribute set of supported application names to the themes for these applications.
The options accepted for each application are determined by the configured `themeOptions` for that application.
However, some options are always accepted:

* `file`: used to place files in the generated theme folders. It is an attribute set of file names to submodules supporting either `text` or `source` options, similar to standard HM file options
* `extraActivationCommands`: additional lines to be placed after the default-generated activation commands for this application and theme

## How to use CLI

Chroma comes with a minimal CLI tool to switch themes called `chromactl`.
It supports the following commands:
* `list-themes`: prints one available theme per line
* `next-theme`: activates the next theme in the order given by `list-themes`. It wraps around at the end of the list.
* `previous-theme`: activates the previous theme in the order given by `list-themes`. It wraps around at the beginning of the list.
* `activate-theme <theme>`: activates a specific theme

## Dynachrome + Palette

There is also a templating system, *Dynachrome* that can be used to generate configuration files for some key colors used by a theme.
These are defined in a theme's *palette*.
It contains definitions both for both semantic colors, which are defined by their purpose, e.g. as background or text color, as well as spectral colors, e.g. shades of green, red, blue, ... that fit with the theme.

### Template Syntax

Templates consist of two parts: frontmatter definitions and the desired, templated file contents.
Frontmatter must be at the beginning of a file and is encased in two lines of `---`.
These lines must encase valid YAML.
Currently a single key is accepted:
`defines`. It contains a map that can define new color overrides:
keys are new names, values are the names of previously defined colors.

In the file contents `⟨name:format⟩` is replaced by the color specified by `name`, formatted as `format`.
Currently, the only supported format is `hex`, which renders the color as `rrggbb`.
I am planning to add more foramts and additional color manipulation functions as they become necessary.

### How to use a Template in a Theme

First, your theme must define its color palette.
Please refer to [palette.nix](https://github.com/Cu3PO42/gleaming-glacier/tree/master/modules/home-manager/copper-chroma/palette.nix) for available options.

The palette module defines a function that is used to instantiate templates.
An idiomatic use might look like this:
```nix
themeConfig = {config, opts, ...}: {
  file."theme.conf".source = mkDefault (opts.palette.generateDynamic {
    template = ./theme.conf.dyn;
    paletteOverrides = {};
  });
};
```

Overrides are applied *after* the definitions from the frontmatter are evaluated and can be used to finetune a template for a particular theme.

## Supported Applications

Gleaming Glacier supports theming for a number of applications and frameworks out-of-the-box.
Some of them come with some drawbacks and limitations that are documented here.
An empty section implies no limitations are currently known and special remarks not needed.

### Command-Line Applications

The following CLI applications are explicitly supported:

* Bat
* Starship
* Fish

In general, it may be preferable to configure your terminal emulator to use your desired colorscheme for the base16 colors, rather than configuring all applications seperately.
Chroma supports theming Kitty this way.
Support for additional terminal emulators is planned.

### Applications

#### Hyprland

#### Kitty

#### VS Code

Theming VS Code is supported via any themes packaged on the marketplace.
These themes are not included via Nix, but installed directly from the marketplace via their extension ID.
As such it is possible, that a theme might break some day if it vanishes from the marketplace.

Themes are enabled by editing your `settings.json`.
The theme settings are configured not to be syncd, even if the rest of your settings are.
This approach may break if you currently have the settings pane open and active.
The worst that should happen is that your theme does not apply, even if it should.
Anothere switch should fix it.

#### Rofi

:::warn
If you use the Rofi configuration included in this Flake (which is a slightly modified version of the Rofi config in [prasanthrangan's Hyprdots](https://github.com/prasanthrangan/hyprdots)), theming will break if you decide to place your Chroma folder in a non-standard location.
:::

#### Waybar

Theming support for Waybar is implemented by setting a number of CSS variables to colors from your theme.
Your configuration must make use of these variables or theming will be ineffective.

#### Dunst

The only thing that is currently themed is the icon theme.

### Frameworks

#### Gtk

GTK 2, 3, and 4 are all supported with hot reloading.
Many GTK 4 applications are written using libadwaita, which purposefully does not apply any configured themes.
Chroma implements a number of workarounds to these issues that can be enabled via `copper.chroma.gtk.gtk4.libadwaitaSupport`.
They are

* `import`, which links the theme to a folder in your Home directory. It supports all libadwaita applications, but does not support hot-reloading.
* `patch-binary`, which applies binany patches to applications to use a patched version of libadwaita that does support theming. Only applications installed via Home-Manager are supported, in rare instances an application may be missed.
* `patch-overlay`, which uses the same patched version of libadwaita, but uses a nixpkgs overlay to apply it. This reduces the chance of missing any packages, but requires recompiling any applications that use libadwaita.

#### Qt

Theming of Qt5 and Qt6 applications is supported via Qt5Ct/Qt6Ct and Kvantum.
This may not work consistently if you are on a Qt-based DE such as Plasma or LXQt.
Contributions that improve support in this case are welcome.

Theme hot-reloading for Qt applications is not currently supported.
This limitation comes from the underlying technologies, not the Chroma theming system.
If you know how to enable hot theme reloading for Qt, please let me know.