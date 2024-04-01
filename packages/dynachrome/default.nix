{rustPlatform, lib, ...}: rustPlatform.buildRustPackage {
  pname = "dynachrome";
  version = "0.1.0";

  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  meta = with lib; {
    description = "A tool to generate dynamic themes from a palette and template.";
    homepage = "https://github.com/Cu3PO42/gleaming-glacier";
    license = licenses.gpl3Plus;
    maintainers = ["Cu3PO42"];
    platforms = platforms.all;

    mainProgram = "dynachrome";
  };
}