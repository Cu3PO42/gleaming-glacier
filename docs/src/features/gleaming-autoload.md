---
title: Gleaming Autoload
---

# Gleaming Autoload

Gleaming Glacier can automatically populate all standard Flake outputs (and some non-standard ones) from files placed in your repository.
I find this behavior more desirable than having to manually import every module, every host and every package.
This sacrifices some flexibility, but at the same time ensures your configurations remain more consistent.

I use this functionality in my own Flake, and it also available for you to use via the `flakeModules.autoload` module.

The following outputs are populated:

### Host Configurations

NixOS and macOS hosts are configured in `hosts/nixos/` and `hosts/darwin/` respectively.
The principles for both are the same, however:
Any file named `hostname.nix` or folder `hostname` with a `default.nix` provides the configuration for a host with the given `hostname`.
The contents of the file are an attribute set with a single required attribute:
`main` should be a NixOS/nix-darwin module like it would be stored in a `configuration.nix` file.

Additionally, you may specify any properties for the `copperConfig` output that is used by [Copper Plate](/features/plate) and [Copper Mage](/features/mage) here.
In the future, additional outputs may be added.

```nix
{
  copperConfig.mage = {
    secrets = ./secrets;
    publicKey = "ssh-ed25519 YOUR KEY HERE"; 
  };

  main = {...}: {
    copper.features = [
      "zfs"
      "impermanence"
    ];

    users.users.Cu3PO42 = {};

    system.stateVersion = "23.11";
    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
```

`networking.hostname` is automatically set based on the file name.
All modules from the `gleaming.autoload.baseModules.<kind>` setting will also be included.
You can modify this setting to your liking in your Flake configuration.
If you use either the [`lib.mkGleamingFlake`](/reference/lib#mkgleamingflake) function or include my `inherit-copper` module, all applicable modules from my Flake will be included and the base feature enabled via `copper.feature.base.enable = true`.
You can configure this behaviour by setting `copper.inheritModules` or `copper.base` respectively to false.

### User Configurations

Home-Manager configurations are stored in `users/`.
Any file named `user@hostname.nix` or folder `user@hostname` with a `default.nix` provides the configuration for user `user` on a host named `hostname`.
The contents of the file should be an attribute set:

```nix
{
  # Home-Manager module to apply
  main = {...}: {};
  # Architecture of the host system. The given value aarch64-linux is just an
  # example. Adjust it for your usecase
  system = "aarch64-linux";
}
```

`home.userName` is automatically set based on the file name.
Additionally, all my Home-Manager modules are injected and by `standaloneBase` feature is activated.

### Modules

There are three kinds of modules supported by the autoload module: NixOS modules, nix-darwin modules, and Home-Manager modules.
They all use the same module system and work analogously.
Modules are loaded from `modules/<kind>`, `features/<kind>`, and `modules/common`, where `<kind>` is either `nixos`, `darwin`, or `home`.

Files in `modules/<kind>` and `modules/common` are bog-standard modules as expected by the module system.
Files in `features/<kind>` work slightly differently: they are automatically wrapped by [`lib.mkFeatureModule`](/reference/lib).
The main purpose of this is to automatically add a configuration setting that can be used to enable or disable the module.
In essence it is syntactic sugar.

All modules: 'normal' and feature modules will also have any arguments specified in `gleaming.autoload.moduleInjectionArgs` set.
Note that this is not handled via the usual `specialArgs` procedure when the configuration including the module is evaluated, but rather at load time.
This allows you to reference values from your Flake, even when your modules are included elsewhere.

By default, the argument `origin` is injected, which is set to your own Flake.

Also note that this module does not automatically load Flake modules.
Those are handled seperately by the [`lib.mkGleamingFlake`](/reference/lib#mkgleamingflake) function, should you choose to use it.
This is because including modules from your Flake's `flakeModules` output would lead to infinite recursion.

### Packages

Place your packages in the `packages` directory in your Flake root.
Every `.nix` file or directory with a `default.nix` will be treated as a single package.
Every package will receive two additional arguments: `self` and `inputs`.
The first is the set of all `packages` and `legacyPackages` defined in your Flake so that they may depend on one another.
The second are the inputs of your Flake, with [flake-parts magic](https://flake.parts/module-arguments.html#inputs) applied so you can access packages and such without explicitly specifying their acrchitecture.

Legacy Packages work in exactly the same way.
I recommand always using packages unless exposing something that is not strictly a package, for example a Nix function.

### Lib

If you wish to define your own helper functions, put them in the `lib` folder with a `default.nix`.
It will be imported with all inputs of your Flake as an argument.

### Templates

Templates follow a somewhat more manual approach.
If it exists, the `templates/default.nix` from your Flake root is imported.
In it, expose an attribute set of [standard template definitions](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-init).

### Overlays

For overlays, the file at `overlays/default.nix` in your Flake root is imported.
It is expected to be a function, which accepts the same arguments you can pass to a [Flake module](https://flake.parts/module-arguments.html?highlight=module#module-arguments) and return an attribute set of overlays.

### Apps

Apps are similar to packages, but are made only to be invoked via the Nix CLI, not to be installed.
They are commonly used to expose additional entrypoints to packages.
Analogous to [Packages](#packages), you place files or folders containing derivations in the `apps` folder.
Our apps are constructed by running their default executable.

### Chroma Themes

[Chroma](/features/chroma) is my theming system.
It can be extended to support a variety of applications and toolkits.
A theme consists of appropriate themes for these supported applications or at least some of them.
This follows a similar structure as the `packages` output, i.e. it is first indexed by the host platform and then the name of the theme.

### Copper Configs

This output contains additional configuration for tools developed in this crate, in particular [Copper Plate](/features/plate) and [Copper Mage](/features/mage).
This output is automatically filled for hosts loaded by this mechanism.
See [above](#host-configurations).
