{rustPlatform, ...}: rustPlatform.buildRustPackage {
  pname = "dynachrome";
  version = "0.1.0";

  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  meta.mainProgram = "dynachrome";
}