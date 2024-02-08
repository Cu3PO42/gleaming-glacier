{
  inputs = {
    # Use the latest nixpkgs.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Reference Copper's dotfiles for configuration re-use
    copper.url = "github:Cu3PO42/gleaming-glacier";
    # Replace the upstream's nixpkgs with our own, so we don't unnecessarily
    # duplicate dependencies.
    copper.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: inputs.copper.lib.mkGleamingFlake inputs ./. "myprefix" (flakeModules: {
    # Your custom flake attrributes go here!
  });
}
