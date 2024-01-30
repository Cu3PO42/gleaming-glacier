{
  systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

  perSystem = {pkgs, ...}: {
    # Required to make nix fmt work
    formatter = pkgs.alejandra;
  };
}