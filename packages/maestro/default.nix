{rustPlatform, lib, ...}: rustPlatform.buildRustPackage {
  pname = "maestro";
  version = "0.1.0";

  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  meta = with lib; {
    description = "Utility to show available keybindings and enable modal keymap timeouts.";
    homepage = "https://github.com/Cu3PO42/gleaming-glacier";
    license = licenses.gpl3Plus;
    maintainers = ["Cu3PO42"];
    platforms = platforms.darwin ++ platforms.linux;
  };
}