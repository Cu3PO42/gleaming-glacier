{
  config,
  lib,
  origin,
  ...
}: let
  cfg = config.services.niks3;
  cache = import ../../../shared/nix-cache.nix;
  secretNames = [
    "niks3-api-token"
    "niks3-signing-key"
    "niks3-s3-access-key"
    "niks3-s3-secret-key"
  ];
in {
  imports = [origin.inputs.niks3.nixosModules.default];

  services.niks3 = {
    enable = true;
    httpAddr = "127.0.0.1:5751";
    database.createLocally = true;

    apiTokenFile = config.age.secrets.niks3-api-token.path;
    signKeyFiles = [config.age.secrets.niks3-signing-key.path];

    s3 = {
      inherit (cache) endpoint bucket region;
      useSSL = true;
      accessKeyFile = config.age.secrets.niks3-s3-access-key.path;
      secretKeyFile = config.age.secrets.niks3-s3-secret-key.path;
    };

    # Clients read directly from private OVH storage using read-only S3
    # credentials managed by agenix. The server handles uploads and GC only.
    readProxy.enable = false;

    # Prefer upstream caches (cache.nixos.org uses 40) over our own storage.
    priority = 50;

    gc = {
      enable = true;
      olderThan = "720h";
      schedule = "daily";
    };
  };

  # copper.mage discovers the encrypted files in ./secrets automatically.
  # Both the server and its GC service must be able to read them.
  age.secrets = lib.mkIf cfg.enable (lib.genAttrs secretNames (_: {
    owner = cfg.user;
    group = cfg.group;
    mode = "0400";
  }));

  # Upstream uses store paths for the server and GC commands but does not
  # install the CLI in PATH. Include it here for manual administration.
  environment.systemPackages = lib.mkIf cfg.enable [cfg.package];
}
