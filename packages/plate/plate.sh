#!/bin/bash

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/plate"

hosts() {
    [ -e "$CONFIG/hosts.json" ] && cat "$CONFIG/hosts.json" || echo "{}"
}

FLAKE="$2"
if [[ $FLAKE =~ ^(.*)\#([^\#\"]*)$ ]]; then
    FLAKE_REF="${BASH_REMATCH[1]}"
    FLAKE_ATTR="${BASH_REMATCH[2]}"
else
    FLAKE="$(hosts | jq -r --arg host "$FLAKE" '.[$host]')"
    if [[ $FLAKE =~ ^(.*)\#([^\#\"]*)$ ]]; then
        FLAKE_REF="${BASH_REMATCH[1]}"
        FLAKE_ATTR="${BASH_REMATCH[2]}"
    else 
        echo "Host must be specified in the form <flake-ref>#<host> or <host> if the flake is already known from a previous command." >&2
        exit 1
    fi
fi

# shellcheck disable=SC1090
source "$(nix build "$FLAKE_REF#nixosConfigurations.\"$FLAKE_ATTR\".config.system.build.plateVars" --print-out-paths --no-link)"

updateHosts() {
    mkdir -p "$CONFIG"
    if [[ $FLAKE_REF =~ ^([.]($|/)|/) ]]; then
        FLAKE_REF="$(realpath "$FLAKE_REF")"
    fi
    NEW_HOSTS="$(hosts | jq --arg host "$FLAKE_ATTR" --arg flake "$FLAKE_REF#$FLAKE_ATTR" '. + {($host): $flake}')"
    echo "$NEW_HOSTS" > "$CONFIG/hosts.json"
}


provision() {
    TEMP=$(mktemp -d)
    trap 'rm -rf "$TEMP"' EXIT

    if [ -n "$HOST_KEY" ]; then
        TOTAL_KEY_LOCATION="$TEMP$HOST_KEY_LOCATION"
        mkdir -p "$(dirname "$TOTAL_KEY_LOCATION")"
        op read "$HOST_KEY" > "$TOTAL_KEY_LOCATION"
        chmod 600 "$TOTAL_KEY_LOCATION"
        ssh-keygen -y -f "$TOTAL_KEY_LOCATION" > "$TOTAL_KEY_LOCATION.pub"
    fi

    if [ -n "$DISK_ENCRYPTION_KEY" ]; then
        DEK_ARGS=( --disk-encryption-keys /tmp/dek.key <(op read "$DISK_ENCRYPTION_KEY") )
    else
        DEK_ARGS=()
    fi

    nixos-anywhere --flake "$FLAKE" \
        --extra-files "$TEMP" \
        "${DEK_ARGS[@]}" \
        "root@$TARGET"

    if [ -n "$HOST_KEY" ]; then
        ssh-keygen -R "$TARGET"
        echo "$TARGET $(cat "$TOTAL_KEY_LOCATION.pub")" >> ~/.ssh/known_hosts
    fi
}

update() {
    if [ -z "$TARGET_USER" ]; then
        TARGET_USER="$(whoami)"
    fi
    NIX_SSHOPTS="-o ForwardAgent=yes" nixos-rebuild --flake "$FLAKE" --target-host "$TARGET_USER@$TARGET" switch --fast --use-remote-sudo --use-substitutes
}

unlock() {
    TEMP=$(mktemp)
    trap 'rm -f "$TEMP"' EXIT
    echo "$TARGET $(cat "$INITRD_PUBLIC_KEY")" > "$TEMP"

    op read "$DISK_ENCRYPTION_KEY" | ssh "root@$TARGET" -T -o "UserKnownHostsFile=$TEMP" -o StrictHostKeyChecking=yes
}

case "$1" in 
    provision)
        provision
        ;;
    update)
        update
        ;;
    unlock)
        unlock
        ;;
    *)
        echo "Usage: $0 <provision|update|unlock> <flake-uri>#<host>" >&2
        exit 1
        ;;
esac

updateHosts
