{
  config,
  lib,
  origin,
  ...
}: let
  cfg = config.copper.feature.private-nix-cache;
  cache = import ../../shared/nix-cache.nix;
in {
  imports = [origin.inputs.agenix.nixosModules.age];

  featureOptions = {
    publicKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = cache.publicKey;
      description = "Trusted cache signing public key, shared through shared/nix-cache.nix by default.";
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.publicKey != null;
        message = "Set shared/nix-cache.nix publicKey before enabling private-nix-cache.";
      }
    ];

    # Mage discovers the encrypted file in each host's configured secret
    # folder. This feature only sets its permissions and consumes its paths.
    age.secrets.nix-cache-credentials = {
      owner = "root";
      mode = "0400";
    };

    systemd.services.nix-daemon = {
      environment.AWS_SHARED_CREDENTIALS_FILE = config.age.secrets.nix-cache-credentials.path;
      restartTriggers = [config.age.secrets.nix-cache-credentials.file];
    };

    nix.settings = {
      extra-substituters = [
        "s3://${cache.bucket}?endpoint=${cache.endpoint}&scheme=https&region=${cache.region}&profile=azurite-cache&priority=50"
      ];
      extra-trusted-public-keys = lib.optional (cfg.publicKey != null) cfg.publicKey;
    };
  };
}
