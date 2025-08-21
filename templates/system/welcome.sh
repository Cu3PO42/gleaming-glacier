#!/bin/bash

set -e

cd "$(dirname "$0")"

echo -n "We're setting some things up. This should not take too long..."

if [ ! -d ./.git ]; then
    if ! git init; then
        echo -e "\r\e[KCould not create a Git repository for your flake. Please make sure Git is installed and working." >&2
        exit 1
    fi
fi
git add --all >/dev/null 2>&1
nix flake lock >/dev/null 2>&1 || echo -e "\r\e[KCould not lock your Nix flake. This is potentially an issue with your internet connection." >&2

DEPS=( "gum" "gnused" )
PATH="$(nix eval --raw --impure --expr "let inherit ((builtins.getFlake ''$(pwd)'').inputs) nixpkgs; in with nixpkgs.\${builtins.currentSystem}; nixpkgs.lib.makeBinPath [ ${DEPS[@]} ]"):$PATH"
echo -ne "\r\e[K" # Clear the previous line.

gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Hi! Welcome to Copper's Flake Template!"
echo "In the Gleaming Framework, all of the features defined in your configuration will be scoped to a namespace. You must choose the prefix for your Flake. While it is possible to change it later, you may need to edit it in a bunch of places, so choose wisely."
echo "Please enter the namespace of your choice:"
NAMESPACE=""
while [ -e "$NAMESPACE" ]; do
    NAMESPACE=$(gum write --placeholder "mynamespace")
    if ! gum confirm "Do you want to use the namespace `$NAMESPACE`?"; then
        NAMESPACE=""
    fi
done

sed -i flake.nix "s/myprefix/$NAMESPACE"

echo "This script will now self-destroy. You won't need it anymore! Goodbye!"
rm "$0"