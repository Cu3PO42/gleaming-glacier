---
title: Library functions
---

# Library functions

Gleaming Glacier includes a small API surface that is designed for external consumption.
Additional library functions exist and are exported, but I make no guarantees as to their stability.

## mkGleamingFlake

```hs
mkGleamingFlake :: Inputs -> Path -> String -> (Map String Module -> Module) -> Outputs
```

This is the main function you want to use if you want to use the Gleaming Flake Framework.
It takes the following arguments:
* all of your flake's inputs,
* the root path of your Flake,
* a namespace of your choice, and finally
* a function that is passed all of your Flake's modules and returns the output module.

Note that your output should be a Flake module as defined by [`flake-parts`](https://flake.parts/).

## mkFeatureModule

```hs
data Args = Args { name :: String, cfg :: ?, description :: String, prefix :: ? }
mkFeatureModule :: Args -> Module
```

Feature modules are a thin abstraction over standard NixOS modules that automatically attain an `enable` attribute and corresponding `mkIf`.

It is used automatically by Gleaming Autoload with modules in the `feature/` directory, but can also be called manually.

* `prefix` is your namespace that you also pass to `mkGleamingFlake`
* `name` is the desired name of the feature; its options will live at `${prefix}.feature.${name}`
* `description` is optional additional text for the `${prefix}.feature.${name}.enable` option
* `cfg` is the configuration module itself.

You may pass either just a `config` body or a standard module body.
