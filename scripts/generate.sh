#!/bin/bash

cd "$(git rev-parse --show-toplevel)"
SYSTEM="$(nix eval --raw --impure --expr "builtins.currentSystem")"

user() {
    mkdir -p ./users
    USER="./users/$(whoami)@$(hostname).nix"
    cat > "$USER" << EOF
{
    modules = [{
        copper.features = [
            "cli"
            "fish"
        ];
        copper.file.symlink.base = "$(pwd)";
    }];
    system = "$SYSTEM";
}
EOF
    echo "Created user configuration at $USER"
    git add "$USER"
}

darwin() {
    mkdir -p ./hosts/darwin

    HOSTNAME="$(hostname)"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --host)
                HOSTNAME="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    HOST="./hosts/darwin/$HOSTNAME.nix"
    cat > "$HOST" << EOF
{
  defaultUser = "$(whoami)";
  copper.features = [
    "cli"
    "finder"
    "fish"
    "install-brew"
  ];
  nixpkgs.hostPlatform = "$SYSTEM";
}
EOF
    echo "Created darwin configuration at $HOST"
    git add "$HOST"
}

if [[ $# -eq 0 ]]; then
    echo "Usage: $(realpath "$0") <user|darwin>"
    exit 1
fi

case "$1" in
    user)
        shift
        user
        ;;
    darwin)
        shift
        darwin "$@"
        ;;
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
esac