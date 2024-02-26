{rustPlatform, ...}: rustPlatform.buildRustPackage {
  pname = "maestro";
  version = "0.1.0";

  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;
}