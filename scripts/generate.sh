#!/bin/bash

cd "$(git rev-parse --show-toplevel)"
SYSTEM="$(nix eval --raw --impure --expr "builtins.currentSystem")"
VERSION="$(nix eval --raw --impure --expr "with (builtins.getFlake ''$(pwd)'').inputs.nixpkgs; lib.versions.majorMinor lib.trivial.version")"

setHost() {
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
}

user() {
    mkdir -p ./users
    USE_HOSTNAME=1
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --single-system)
                USE_HOSTNAME=0
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    if [[ $USE_HOSTNAME -eq 1 ]]; then
        USER="./users/$(whoami)@$(hostname).nix"
    else
        USER="./users/$(whoami).nix"
    fi
    cat > "$USER" << EOF
{
    modules = [{
        copper.features = [
            "cli"
            "fish"
        ];
        copper.file.symlink.base = "$(pwd)";
        home.stateVersion = "$VERSION";
    }];
    system = "$SYSTEM";
}
EOF
    echo "Created user configuration at $USER"
    git add "$USER" > /dev/null
}

darwin() {
    setHost "$@"

    mkdir -p ./hosts/darwin
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
  darwin.stateVersion = "$VERSION";
}
EOF
    echo "Created darwin configuration at $HOST"
    git add "$HOST" > /dev/null
}

nixos() {
    setHost "$@"

    mkdir -p ./hosts/nixos
    HOST="./hosts/nixos/$HOSTNAME.nix"
    cat > "$HOST" << EOF
{
  main = {
    copper.features = [
      "base"
    ];
    system.stateVersion = "$VERSION";
    nixpkgs.hostPlatform = "$SYSTEM";
  };
}
EOF
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
    nixos)
        shift
        nixos "$@"
        ;;
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
esac