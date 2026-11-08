#!/usr/bin/env bash
set -euo pipefail

# Run with agenix, age, age-keygen, and git available. Nix and 1Password
# metadata are stubbed; editing and decryption use real agenix and age.
mage_script=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/packages/mage/mage.sh
export MAGE_TEST_AGENIX=${AGENIX_BIN:-$(command -v agenix)}
age_bin=${AGE_BIN:-$(command -v age)}
age_keygen_bin=${AGE_KEYGEN_BIN:-$(command -v age-keygen)}
work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT

export MAGE_TEST_ROOT="$work_dir/repo"
export TMPDIR="$work_dir/tmp"
mkdir -p "$TMPDIR" "$work_dir/bin" \
  "$MAGE_TEST_ROOT/hosts/nixos/alpha/secrets" \
  "$MAGE_TEST_ROOT/hosts/nixos/beta/secrets"
git -C "$MAGE_TEST_ROOT" init -q

export MAGE_TEST_IDENTITY="$work_dir/root.agekey"
"$age_keygen_bin" -o "$MAGE_TEST_IDENTITY" 2>/dev/null
"$age_keygen_bin" -o "$work_dir/alpha.agekey" 2>/dev/null
"$age_keygen_bin" -o "$work_dir/beta.agekey" 2>/dev/null
MAGE_TEST_ROOT_PUBLIC=$("$age_keygen_bin" -y "$MAGE_TEST_IDENTITY")
MAGE_TEST_ALPHA_PUBLIC=$("$age_keygen_bin" -y "$work_dir/alpha.agekey")
MAGE_TEST_BETA_PUBLIC=$("$age_keygen_bin" -y "$work_dir/beta.agekey")
export MAGE_TEST_ROOT_PUBLIC MAGE_TEST_ALPHA_PUBLIC MAGE_TEST_BETA_PUBLIC

cat > "$work_dir/bin/nix" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  *ageRootKey.private*) printf '%s\n' 'op://test/root/private key' ;;
  *ageRootKey.public*) printf '%s\n' "$MAGE_TEST_ROOT_PUBLIC" ;;
  *opAccount*) printf '%s\n' 'test-account' ;;
  *copperConfig.alpha.mage.publicKey*) printf '%s\n' "$MAGE_TEST_ALPHA_PUBLIC" ;;
  *copperConfig.beta.mage.publicKey*) printf '%s\n' "$MAGE_TEST_BETA_PUBLIC" ;;
  *copperConfig.alpha.mage.secrets*) printf '%s\n' '/nix/store/test-source/hosts/nixos/alpha/secrets' ;;
  *copperConfig.beta.mage.secrets*) printf '%s\n' '/nix/store/test-source/hosts/nixos/beta/secrets' ;;
  *) exit 1 ;;
esac
MOCK

cat > "$work_dir/bin/op" <<'MOCK'
#!/usr/bin/env bash
cat -- "$MAGE_TEST_IDENTITY"
MOCK

cat > "$work_dir/bin/dos2unix" <<'MOCK'
#!/usr/bin/env bash
cat
MOCK

cat > "$work_dir/bin/agenix" <<'MOCK'
#!/usr/bin/env bash
exec "$MAGE_TEST_AGENIX" "$@"
MOCK
chmod +x "$work_dir/bin/"*
export PATH="$work_dir/bin:$PATH"

run_mage() {
  bash -euo pipefail "$mage_script" "$@"
}

# Both hosts intentionally use the same filename. Rules in TMPDIR would
# send both edits to the same file there, rather than each host directory.
printf '%s\n' alpha-value | run_mage edit "$MAGE_TEST_ROOT#alpha" reader
printf '%s\n' beta-value | run_mage edit "$MAGE_TEST_ROOT#beta" reader
alpha_file="$MAGE_TEST_ROOT/hosts/nixos/alpha/secrets/reader.age"
beta_file="$MAGE_TEST_ROOT/hosts/nixos/beta/secrets/reader.age"
test -f "$alpha_file"
test -f "$beta_file"
test ! -e "$TMPDIR/reader.age"
test "$("$age_bin" -d -i "$work_dir/alpha.agekey" "$alpha_file")" = alpha-value
test "$("$age_bin" -d -i "$work_dir/beta.agekey" "$beta_file")" = beta-value

printf '%s\n' alpha-updated | run_mage edit "$MAGE_TEST_ROOT#alpha" reader
test "$(run_mage decrypt "$MAGE_TEST_ROOT#alpha" reader)" = alpha-updated
test "$(run_mage decrypt "$MAGE_TEST_ROOT#beta" reader)" = beta-value
test -z "$(find "$MAGE_TEST_ROOT" -name '.mage-rules.*.nix' -print)"
printf '%s\n' 'Mage edit/decrypt preserve per-host paths and clean up temporary rules.'
