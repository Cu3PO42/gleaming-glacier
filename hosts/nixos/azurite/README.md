# Private niks3 cache on OVHcloud

The cache uses one private OVH bucket, `cupper-private-nix-cache`, in Frankfurt:
`https://s3.de.io.cloud.ovh.net/`, signing region `de`.
[shared/nix-cache.nix](../../../shared/nix-cache.nix) holds these shared
settings and the public signing key. Bucket names are not secrets; knowing
the name does not grant access to the contents. If you rename/recreate the
bucket, update that shared configuration and the bucket ARNs in both JSON
policy files before importing them in OVH.

Azurite runs niks3 and PostgreSQL. Malachite and azurite read directly from
OVH through the shared `private-nix-cache` feature. Reads use a separate,
read-only S3 identity per host. The niks3 read proxy is disabled. Its upload
API listens on loopback behind Caddy at `https://niks3.libethenite.dev`, with
automatic HTTPS certificates and HTTP-to-HTTPS redirects. Public
access to this API does not make cache objects publicly readable.

`shared/nix-cache.nix` also holds `upload.domain`, the derived `upload.url`,
and the exact repository/ref allowlists in `ci`. Both the server's OIDC
policy and GitHub Actions consume these settings. Change the domain there
when moving the endpoint, update its DNS, and deploy azurite before running
CI with the new URL. No workflow URL or GitHub secret needs updating.

Create an A record for **niks3.libethenite.dev** pointing at azurite's
`128.140.125.200`. The apex domain's A record does not cover this subdomain.
If you add an AAAA record, it must also point at azurite. TCP ports 80 and
443 must be reachable for certificate issuance and HTTPS. Caddy's NixOS
module opens both, plus UDP 443 for HTTP/3. Port 5751 remains bound to
loopback. Caddy's certificates and state live in `/var/lib/caddy` on the
persistent `/var/lib` dataset.

Azurite enables the shared Caddy service and firewall integration in
`default.nix`; each proxied service adds a `services.caddy.virtualHosts`
entry. The niks3 virtual host preserves upstream's 128 MiB request-body
limit and 300-second proxy timeouts. Upstream's nginx integration is
disabled. Its optional mTLS headers/socket are not used: niks3 validates
OIDC and API bearer tokens itself.

## 1. Prepare the checkout

From the repository root, stage the configuration files so Git-backed Nix
flakes can see the new modules and malachite's secret directory:

```sh
git add flake.nix flake.lock shared/nix-cache.nix \
  features/nixos/private-nix-cache.nix hosts/nixos/azurite \
  hosts/nixos/malachite/default.nix hosts/nixos/malachite/secrets/.gitkeep
```

Mage uses the age root key in 1Password and each host's public key to encrypt
secrets for both recipients. Make sure the 1Password CLI integration is
available and the application is unlocked.

Malachite's public key was taken from its 1Password host-key item. Agenix
needs the matching private key at `/etc/ssh/ssh_host_ed25519_key`; the `.pub`
file is not required. Check on malachite before deployment:

```sh
sudo ssh-keygen -y -f /etc/ssh/ssh_host_ed25519_key
```

If OpenSSH rejects a regular private-key file because its permissions are
too open, set its owner to root and restrict it to root before retrying:

```sh
sudo chown root:root /etc/ssh/ssh_host_ed25519_key
sudo chmod 600 /etc/ssh/ssh_host_ed25519_key
sudo ssh-keygen -y -f /etc/ssh/ssh_host_ed25519_key
```

Check symlink targets before changing permissions. These commands preserve
the key contents. Mode `0644` permits other local users to read the key;
restricting permissions does not revoke copies already made.

The public key output must match `copperConfig.mage.publicKey` in malachite's
configuration. If the private file is missing or differs, resolve the host
identity first; the secrets must be encrypted to the key actually used by
agenix. Azurite reads its identity from
`/persist/etc/ssh/ssh_host_ed25519_key` through its existing configuration.

## 2. Create three OVH S3 users

Open **Public Cloud → your project → Storage → Object Storage → Users**.
Create distinct users, for example:

| User | Purpose | Bucket role |
| --- | --- | --- |
| `niks3-azurite` | Server uploads and GC | Read and write |
| `nix-cache-malachite` | Read-only substitution on malachite | Read-only |
| `nix-cache-azurite` | Read-only substitution on azurite | Read-only |

Save each user's S3 Access Key ID and Secret Access Key in 1Password. Assign
these roles on `cupper-private-nix-cache` when adding the users to the bucket.
The presets cover normal cache uploads, reads, and garbage collection.

The JSON policies in this directory are an alternative for explicit
permissions. If needed, open the Object Storage **Users** tab and use the
user's **… → Import a policy** action. Import replaces the user's current
policy. Use fresh reader users, rather than reusing the bucket owner's
identity: the owner's ACL permissions can defeat an allow-only read
restriction.

The server policy grants operations only on this bucket and its objects,
including deletes, multipart uploads, and lifecycle cleanup. The reader
policy allows reading objects, listing the bucket, and querying its location. These are S3
credentials; no OVH management API application key is required for niks3.

Keep the bucket private. Leave Object Lock disabled for the cache and avoid
object-expiration rules; niks3 manages reference-aware GC. Its own lifecycle
rule aborts incomplete multipart uploads. The read/write preset may not
permit managing bucket lifecycle rules; that causes a startup warning but
does not prevent normal operation or niks3 GC. If needed, import the server
JSON policy, which includes lifecycle permissions, or configure an
incomplete-multipart-upload abort rule in OVH and set
`services.niks3.abortIncompleteUploadsDays = 0` to disable automatic rule
management. This option does not disable niks3's GC.

See [OVH's identity and access guide](https://docs.ovhcloud.com/en/guides/storage-and-backup/object-storage/s3-identity-and-access-management).

## 3. Encrypt the server's S3 credentials

Run these commands one at a time. Each opens your editor; enter only the
corresponding value from the `niks3-azurite` S3 user, save, and close:

```sh
nix run .#mage -- edit .#azurite niks3-s3-access-key
nix run .#mage -- edit .#azurite niks3-s3-secret-key
```

The first contains the Access Key ID; the second contains the Secret Access
Key. Do not put INI sections or quotes around these individual values.
The encrypted files go under `hosts/nixos/azurite/secrets/` and are assigned
to the `niks3` system user at activation.

## 4. Generate the niks3 API token and signing key

Generate an API token locally and put the output in a new Mage secret:

```sh
nix shell --inputs-from . nixpkgs#openssl --command openssl rand -hex 32
nix run .#mage -- edit .#azurite niks3-api-token
```

Keep a copy of this API token in 1Password for manual administration.
It authorizes uploads and GC; reader-only hosts do not need it. GitHub
Actions uses short-lived OIDC tokens with only the `write` scope and does
not receive this token, the signing key, or S3 credentials.

Generate the cache signing key locally and put its complete single-line
output in the signing secret:

```sh
nix key generate-secret --key-name azurite-cache-1
nix run .#mage -- edit .#azurite niks3-signing-key
```

Keep an encrypted backup in 1Password. Derive the public signing key without
printing the private key again:

```sh
nix run .#mage -- decrypt .#azurite niks3-signing-key \
  | nix key convert-secret-to-public
```

Replace `publicKey = null;` in `shared/nix-cache.nix` with the resulting
`"azurite-cache-1:..."` public key. Only that public key belongs in plain Nix
configuration. Keep all generated secret values out of chat and Git.

## 5. Encrypt each host's reader credentials

Use the reader user for the corresponding host:

```sh
nix run .#mage -- edit .#malachite nix-cache-credentials
nix run .#mage -- edit .#azurite nix-cache-credentials
```

Each editor buffer must contain an AWS shared credentials file:

```ini
[azurite-cache]
aws_access_key_id = THIS_HOSTS_READ_ONLY_ACCESS_KEY_ID
aws_secret_access_key = THIS_HOSTS_READ_ONLY_SECRET_ACCESS_KEY
```

Mage discovers each host's encrypted file from its configured secret folder.
The shared feature sets the secret's permissions, makes it readable only by root,
and sets `AWS_SHARED_CREDENTIALS_FILE` for `nix-daemon`. It also configures
the S3 substituter and signing public key. It restarts the daemon when the
encrypted credential file changes. Interactive AWS environment variables
alone do not configure the daemon.

Secret locations are managed by Mage through each host's `copperConfig.mage`.
The named AWS profile is `azurite-cache`, independent of any default AWS
profile you may already use. The S3 URL includes priority 50, after
`cache.nixos.org` at 40.

See [Nix S3 authentication](https://nix.dev/manual/nix/2.34/store/types/s3-binary-cache-store.html#authentication).

## 6. Enable and deploy

At this point there should be four server secrets and two reader files:

```text
hosts/nixos/azurite/secrets/niks3-s3-access-key.age
hosts/nixos/azurite/secrets/niks3-s3-secret-key.age
hosts/nixos/azurite/secrets/niks3-api-token.age
hosts/nixos/azurite/secrets/niks3-signing-key.age
hosts/nixos/azurite/secrets/nix-cache-credentials.age
hosts/nixos/malachite/secrets/nix-cache-credentials.age
```

Set `services.niks3.enable = true` in azurite's `niks3.nix`. Start the server
before enabling the readers, so it initializes `nix-cache-info` in the
bucket. Stage the encrypted files and validate/deploy azurite:

```sh
git add shared/nix-cache.nix hosts/nixos/azurite hosts/nixos/malachite/secrets
nix eval --raw .#nixosConfigurations.azurite.config.system.build.toplevel.drvPath
nix run .#plate -- update .#azurite --build-on-remote
```

Then uncomment `"private-nix-cache"` in both hosts' `copper.features` lists.
Validate each system and activate the reader configuration on each machine.
On malachite, run this from the repository root:

```sh
sudo nixos-rebuild switch --flake .#malachite
sudo stat -c '%U %a %n' /run/agenix/nix-cache-credentials
```

The credential file should be owned by root with mode `400`. Deploy
azurite again after enabling its reader feature:

```sh
nix run .#plate -- update .#azurite --build-on-remote
```

Agenix decrypts the reader credentials during system activation. Deploying
the server on azurite does not activate malachite's reader configuration.
If `/run/agenix` is missing on malachite, first confirm that its local system
was rebuilt and switched successfully with `private-nix-cache` enabled.

PostgreSQL and `/var/lib/niks3` live on azurite's persistent `/var/lib` ZFS
dataset. Daily GC expires closures older than 30 days. Uploads must go
through `niks3 push`, rather than `nix copy --to s3://...`, so their references
are tracked in PostgreSQL. CI explicitly uploads successful job outputs;
automatic uploads from local builds still need a separate post-build hook.
Configuring substitution does not enable uploads.

## CI uploads

The GitHub Actions workflow pushes each successful build job's output
closure, including outputs restored by Hestia, through `niks3 push`.
Hestia continues to handle intermediate build caching and derivation
distribution within GitHub Actions. The niks3 action runs with `skip-push`
so it does not replace Hestia's post-build hook. Explicit pushes fail the
job if authentication or uploading fails.

niks3 stores the complete runtime closure, including upstream dependencies.
It deduplicates objects already in our cache, but does not exclude paths
available from other caches. Hestia separately filters NixOS- and Nix
Community-signed paths from its Actions cache using the
`hestia.upstreamCacheKeyNames` list in [`ci/cache.nix`](../../../ci/cache.nix).
We retain the upstream niks3 client and
measure S3 usage before considering a custom filtering client.

Initially, uploads are allowed only for `push` and `workflow_dispatch`
events on `refs/heads/master` in `Cu3PO42/gleaming-glacier`. Edit the exact
`ci.repositories` and `ci.refs` lists in `shared/nix-cache.nix` to authorize
other repositories or branches, and deploy the server policy first.
The server checks repository, ref, event, issuer, and audience independently
of the workflow's upload condition. Pull requests, forks, and other refs
still build with Hestia but do not upload to the private cache.

The reusable build workflow gets `id-token: write` from its caller. The
niks3 action discovers the audience and signing public key from
`/api/cache-config`; `cacheUrl` stays unset so the API is not added as a
public read substituter. No GitHub cache credentials need provisioning.
See [CI configuration](../../../ci/README.md#private-niks3-uploads).

Hestia omits fully cached jobs from its matrix. Such jobs do not run an
upload step, so this is not a backfill of old Hestia entries into S3.

## Measuring storage

Use OVH's usage/billing view to track stored data, operations, and transfer.
Compare the initial cache fill with later nixpkgs updates and the effect of
the existing 30-day closure retention. Shared NARs are stored once, so each
CI job does not create another copy of the same dependencies.

For a current-object inventory, enter a shell with the AWS CLI on azurite:

```sh
nix shell --inputs-from . nixpkgs#awscli2
```

Then use the existing read-only credentials (adjust the bucket/endpoint
below if you change the shared storage configuration):

```sh
sudo env AWS_SHARED_CREDENTIALS_FILE=/run/agenix/nix-cache-credentials \
  "$(command -v aws)" --profile azurite-cache \
    --endpoint-url https://s3.de.io.cloud.ovh.net --region de \
    s3api list-objects-v2 --bucket cupper-private-nix-cache \
    --query '{objects: length(Contents || `[]`), bytes: sum(Contents[].Size || `[]`)}' \
    --output json --no-cli-pager
```

AWS CLI automatically paginates this JSON query. It lists metadata without
downloading NARs; the byte total measures current object sizes after
compression. It excludes noncurrent versions and incomplete multipart
uploads, so OVH billing remains authoritative. niks3's `/api/cache-stats`
reports logical bytes and should not be used as the compressed storage
total.

## 7. Test uploads and authenticated reads

After deploying Caddy and configuring DNS, check the public API:

```sh
cache_url=$(nix eval --raw --file ./shared/nix-cache.nix --apply 'cache: cache.upload.url')
curl --fail "$cache_url/api/cache-config?issuer=https://token.actions.githubusercontent.com"
```

The response should advertise the matching `oidc_audience` and public key,
with an empty `substituter_url`. An unauthenticated POST to
`/api/pending_closures` must fail, and a GET for a known `.narinfo` path
through this URL must not return the object. Trigger CI on an allowed ref
to verify a complete OIDC upload; GitHub's token cannot be minted locally.

For a manual upload, use a securely stored local copy of the API token:

```sh
export NIKS3_SERVER_URL="$cache_url"
export NIKS3_AUTH_TOKEN_FILE=/path/to/api-token
nix build --inputs-from . nixpkgs#hello --out-link /tmp/azurite-cache-hello
nix run --inputs-from . niks3 -- push /tmp/azurite-cache-hello
```

An SSH upload tunnel remains available for administration:

```sh
ssh -N -L 5751:127.0.0.1:5751 Cu3PO42@128.140.125.200
```

In another terminal, select the tunnel instead of HTTPS:

```sh
export NIKS3_SERVER_URL=http://127.0.0.1:5751
nix run --inputs-from . niks3 -- push /tmp/azurite-cache-hello
```

After activating the reader feature on the machine where you run this
command (for example, malachite), test direct S3 reads into a fresh store.
An explicit `nix copy --from s3://...` accesses S3 in the invoking process,
so give that process access to the decrypted credential file too:

```sh
cache_public_key=$(nix eval --raw --file ./shared/nix-cache.nix --apply 'cache: cache.publicKey')
sudo env AWS_SHARED_CREDENTIALS_FILE=/run/agenix/nix-cache-credentials \
  nix copy \
    --from 's3://cupper-private-nix-cache?endpoint=s3.de.io.cloud.ovh.net&scheme=https&region=de&profile=azurite-cache&priority=50' \
    --to /tmp/azurite-cache-read-test \
    --extra-trusted-public-keys "$cache_public_key" \
    /tmp/azurite-cache-hello
```

Reads require no tunnel and continue working if azurite is offline. Verify
that an unauthenticated request for an existing cache object fails and that
each reader user cannot upload objects. Inspect `journalctl -u niks3 -u niks3-gc`
and `systemctl list-timers niks3-gc.timer` on azurite if needed.
