{
  inputs = {
    # Reference Copper's dotfiles for configuration re-use
    copper.url = "github:Cu3PO42/gleaming-glacier";

    # Use the same nixpkgs as upstream, so that we can use their pre-built packages without
    # duplicating dependencies.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.follows = "copper/nixpkgs";
  };

  outputs = inputs: inputs.copper.lib.mkGleamingFlake inputs ./. "myprefix" (flakeModules: {
    # Your custom flake attrributes go here!
  });
}
