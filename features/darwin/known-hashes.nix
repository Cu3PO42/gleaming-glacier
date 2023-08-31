{...}: {
  environment.etc.shells.knownSha256Hashes = [
    # The default /etc/shells on recent macOS
    "9d5aa72f807091b481820d12e693093293ba33c73854909ad7b0fb192c2db193"
  ];
  environment.etc."nix/nix.conf".knownSha256Hashes = [
    # Nix installer 2.4
    "ff08c12813680da98c4240328f828647b67a65ba7aa89c022bd8072cba862cf1"
  ];
}
