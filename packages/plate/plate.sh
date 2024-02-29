#!/bin/bash

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/plate"

readOpKey() {
    ARG="$1"
    # Fix up 1Password's weird handling of SSH keys over the CLI.
    case "$ARG" in *"private key") ARG="$ARG?ssh-format=openssh" ;; esac
    op read "$ARG" | dos2unix
}

hosts() {
    [ -e "$CONFIG/hosts.json" ] && cat "$CONFIG/hosts.json" || echo "{}"
}

FLAKE_PARSED=0
parseFlake() {
    if [ $FLAKE_PARSED -eq 1 ]; then
        echo "Error: too many positional arguments."
        exit 1
    fi

    FLAKE_PARSED=1
    FLAKE="$1"
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
    source <(nix eval "$FLAKE_REF#copperConfig.\"$FLAKE_ATTR\".build.plate" --raw)
}


updateHosts() {
    mkdir -p "$CONFIG"
    if [[ $FLAKE_REF =~ ^([.]($|/)|/) ]]; then
        FLAKE_REF="$(realpath "$FLAKE_REF")"
    fi
    NEW_HOSTS="$(hosts | jq --arg host "$FLAKE_ATTR" --arg flake "$FLAKE_REF#$FLAKE_ATTR" '. + {($host): $flake}')"
    echo "$NEW_HOSTS" > "$CONFIG/hosts.json"
}


provision() {
    BUILD_ON_REMOTE=0
    PORT="22"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --build-on-remote)
                BUILD_ON_REMOTE=1
                ;;
            --target-user)
                TARGET_USER="$2"
                shift
                ;;
            --port)
                PORT="$2"
                shift
                ;;
            *)
                parseFlake "$1"
                ;;
        esac
        shift
    done
    TARGET_USER=${TARGET_USER:-${DEFAULT_TARGET_USER:-root}}

    TEMP=$(mktemp -d)
    trap 'rm -rf "$TEMP"' EXIT

    if [ -n "$HOST_KEY" ]; then
        TOTAL_KEY_LOCATION="$TEMP$HOST_KEY_LOCATION"
        mkdir -p "$(dirname "$TOTAL_KEY_LOCATION")"
        readOpKey "$HOST_KEY" > "$TOTAL_KEY_LOCATION"
        chmod 600 "$TOTAL_KEY_LOCATION"
        ssh-keygen -y -f "$TOTAL_KEY_LOCATION" > "$TOTAL_KEY_LOCATION.pub"
    fi

    if [ -n "$BUILD_ON_REMOTE" ]; then
        REMOTE_ARGS=( --build-on-remote )
    else
        REMOTE_ARGS=()
    fi

    if [ -n "$DISK_ENCRYPTION_KEY" ]; then
        DEK_FILE=$(mktemp)
        trap 'rm -f "$DEK_FILE"' EXIT
        op read "$DISK_ENCRYPTION_KEY" > "$DEK_FILE"
        DEK_ARGS=( --disk-encryption-keys /tmp/dek.key "$DEK_FILE" )
    else
        DEK_ARGS=()
    fi

    nixos-anywhere --flake "$FLAKE" \
        --extra-files "$TEMP" \
        "${DEK_ARGS[@]}" \
        "${REMOTE_ARGS[@]}" \
        -p "$PORT" \
        "${NIXOS_ANYWHERE_ARGS[@]}" \
        "$TARGET_USER@$TARGET"

    if [ -n "$HOST_KEY" ]; then
        ssh-keygen -R "$TARGET"
        echo "$TARGET $(cat "$TOTAL_KEY_LOCATION.pub")" >> ~/.ssh/known_hosts
    fi
}

update() {
    BUILD_ON_REMOTE=0
    TEST=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --build-on-remote)
                BUILD_ON_REMOTE=1
                ;;
            --target-user)
                TARGET_USER="$2"
                shift
                ;;
            --test)
                TEST=1
                ;;
            *)
                parseFlake "$1"
                ;;
        esac
        shift
    done

    TARGET_USER=${TARGET_USER:-${DEFAULT_TARGET_USER:-$(whoami)}}

    if [ $BUILD_ON_REMOTE -eq 1 ]; then
        REMOTE_ARGS=( --build-host "$TARGET_USER@$TARGET" )
    else
        REMOTE_ARGS=()
    fi

    if [ $TEST -eq 1 ]; then
        CMD="test"
    else
        CMD="switch"
    fi

    NIX_SSHOPTS="-o ForwardAgent=yes" nixos-rebuild --flake "$FLAKE" --target-host "$TARGET_USER@$TARGET" $CMD --fast --use-remote-sudo --use-substitutes "${REMOTE_ARGS[@]}"
}

unlock() {
    SSH_ONLY=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ssh-only)
                SSH_ONLY=1
                ;;
            *)
                parseFlake "$1"
                ;;
        esac
        shift
    done

    # The initrd uses a different host key, so we need to construct an appropriate
    # known_hosts file. Since the connection may be configured using a jump host,
    # which also needs to have its key validated, we start with the original
    # known_hosts file, patching only the line for the target host.
    TEMP=$(mktemp)
    trap 'rm -f "$TEMP"' EXIT
    REAL_HOSTNAME=$(ssh -G "$TARGET" | awk '$1 == "hostname" { print $2 }')
    sed "/^$REAL_HOSTNAME/d" ~/.ssh/known_hosts > "$TEMP"
    echo "$REAL_HOSTNAME $INITRD_PUBLIC_KEY" >> "$TEMP"

    SSH_COMMAND=( ssh "root@$TARGET" -T -o "UserKnownHostsFile=$TEMP" -o StrictHostKeyChecking=yes )

    if [ $SSH_ONLY -eq 1 ]; then
        "${SSH_COMMAND[@]}"
        exit $?
    fi

    if ! DEK_VALUE="$(op read "$DISK_ENCRYPTION_KEY")"; then
        echo "Error: could not read disk encryption key from 1Password."
        echo "Please make sure your account is logged in."
        exit 1
    fi
    echo "$DEK_VALUE" | "${SSH_COMMAND[@]}"
}

cmd="$1"
shift
case "$cmd" in 
    provision)
        provision "$@"
        ;;
    update)
        update "$@"
        ;;
    unlock)
        unlock "$@"
        ;;
    *)
        echo "Usage: $0 <provision|update|unlock> <flake-uri>#<host>" >&2
        exit 1
        ;;
esac

updateHosts
