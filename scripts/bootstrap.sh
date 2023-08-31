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
    if ! nix build ".#homeConfigurations.$(whoami)@$HOSTNAME.activationPackage"; then
        echo "Building your Home-Manager configuration failed. There is most likely a problem in users/$(whoami)@$HOSTNAME."
        echo "Please check the logs above for more information."
        exit 1
    fi
    if ! ./result/activate; then
        echo "Activation of your Home-Manager configuration was not successful. This is most"
        echo "likely because Home-Manager would overwrite files that you already have. If"
        echo "you haven't manually modified any of those files, it is probably safe to"
        echo "overwrite them. Any old files will be renamed with the extension '.backup'."
        echo "If you have modified these files, you will need to manually merge the changes"
        echo "into your Home-Manager configuration or disable features modifying these files."
        echo "Would you like to overwrite these files? [y/n]"
        while true; do
            read -r yn
            case $yn in
                [Yy]* )
                    HOME_MANAGER_BACKUP_EXT=backup ./result/activate
                    break
                    ;;
                [Nn]* )
                    echo "Aborting activation. Please manually merge your changes to those files, move"
                    echo "them and re-run the bootstrap script."
                    exit 1
                    ;;
                * )
                    echo "Please answer yes or no."
                    ;;
            esac
        done
    fi
fi