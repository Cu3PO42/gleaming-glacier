{
  systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];

  perSystem = {pkgs, ...}: {
    # Required to make nix fmt work
    formatter = pkgs.alejandra;
  };
}