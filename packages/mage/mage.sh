#!/usr/bin/env bash

readOpKey() {
    ARG="$1"
    # Fix up 1Password's weird handling of SSH keys over the CLI.
    case "$ARG" in *"private key") ARG="$ARG?ssh-format=openssh" ;; esac
    op read "$ARG" | dos2unix
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
        echo "Host must be specified in the form <flake-ref>#<host> or <host> if the flake is already known from a previous command." >&2
        exit 1
    fi
}

setupKeys() {
    GIT_ROOT=$( (cd "$FLAKE_REF"; git rev-parse --show-toplevel) )

    ROOT_KEY_REF=$(nix eval --file "$GIT_ROOT/mage.nix" --apply 'e: e.ageRootKey.private' --raw)
    ROOT_KEY_PUBLIC=$(nix eval --file "$GIT_ROOT/mage.nix" --apply 'e: e.ageRootKey.public' --raw)
    OP_ACCOUNT=$(nix eval --file "$GIT_ROOT/mage.nix" --apply 'e: e.opAccount' --raw)
    export OP_ACCOUNT

    HOST_KEY=$(nix eval "$FLAKE_REF#copperConfig.$FLAKE_ATTR.mage.publicKey" --raw)
    SECRET_FOLDER=$(nix eval "$FLAKE_REF#copperConfig.$FLAKE_ATTR.mage.secrets" | sed 's|/nix/store/[^/]*/||')

    SECRET_PATH="$GIT_ROOT/$SECRET_FOLDER"

    SECRETS_DEF=$(mktemp)
    trap 'rm -f "$SECRETS_DEF"' EXIT
    echo "{\"$FILE.age\".publicKeys=[\"$ROOT_KEY_PUBLIC\" \"$HOST_KEY\"];}" > "$SECRETS_DEF"
}

edit() {
    parseFlake "$1"
    FILE="$2"

    setupKeys

    pushd "$SECRET_PATH" > /dev/null
    RULES="$SECRETS_DEF" agenix -e "$FILE.age" -i <(readOpKey "$ROOT_KEY_REF")
    popd > /dev/null
}

decrypt() {
    parseFlake "$1"
    FILE="$2"

    setupKeys
 
    pushd "$SECRET_PATH" > /dev/null
    RULES="$SECRETS_DEF" agenix -d "$FILE.age" -i <(readOpKey "$ROOT_KEY_REF")
    popd > /dev/null
}

cmd="$1"
shift
case "$cmd" in
    edit)
        edit "$@"
        ;;
    decrypt)
        decrypt "$@"
        ;;
    *)
        echo "Unknown command: $cmd" >&2
        exit 1
        ;;
esac

# TODO: rekey?
