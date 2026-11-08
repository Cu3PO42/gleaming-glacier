{
  # Shared by the niks3 server and every private-nix-cache client.
  bucket = "cupper-private-nix-cache";
  endpoint = "s3.de.io.cloud.ovh.net";
  region = "de";

  publicKey = "azurite-cache-1:PF+uxma3gpxus439MM6XsED0gEyUmsJIrJhXuOMZJXY=";

  # Public upload API only; cache objects require private S3 credentials.
  # CI reads this URL during evaluation and passes it to every build job.
  upload = rec {
    domain = "niks3.libethenite.dev";
    url = "https://${domain}";
  };

  ci = {
    # Exact matches, shared by the workflow and the server's OIDC policy.
    repositories = ["Cu3PO42/gleaming-glacier"];
    refs = ["refs/heads/master"];

    # Hestia's filter replaces its default key list when explicitly configured.
    # Keep the NixOS key alongside every additional upstream cache we use.
    upstreamCacheKeyNames = [
      "cache.nixos.org-1"
      "nix-community.cachix.org-1"
    ];
  };
}
