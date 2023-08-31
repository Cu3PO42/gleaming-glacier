#!/bin/bash

# Parse arguments: --host [hostname] --user
DO_HOST=0
DO_USER=0
HOSTNAME="$(hostname)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)
            DO_HOST=1
            shift
            ;;
        --hostname)
            HOSTNAME="$1"
            shift
            ;;
        --user)
            DO_USER=1
            shift 1
            ;;
        *)
            shift
            ;;
    esac
done

if [[ $DO_HOST -eq 1 ]]; then
    # If darwin
    if [[ "$OSTYPE" == "darwin"* ]]; then
        nix build ".#darwinConfigurations.$HOSTNAME.system" --extra-experimental-features "nix-command flakes"
        ./result/sw/bin/darwin-rebuild switch --flake ".#$HOSTNAME"

        # The previous step may install XCode, which breaks Git unless we accept the license
        # if xcodebuild exists
        if command -v xcodebuild &> /dev/null; then
            sudo xcodebuild -license
        fi
    fi

    # If /etc/NIXOS exists
    if [[ -d "/etc/NIXOS" ]]; then
        nixos-rebuild switch --flake ".#$HOSTNAME"
    fi
fi

if [[ $DO_USER -eq 1 ]]; then
    nix build ".#homeConfigurations.$(whoami)@$HOSTNAME.activationPackage"
    ./result/activate
fi