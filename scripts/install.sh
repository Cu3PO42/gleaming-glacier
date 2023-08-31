#!/bin/bash

mac_deps() {
  # Set up pre-requisites
  xcode-select --install || true
  if [[ $(arch) == 'arm64' ]]; then
    # Ask if the user wants to install Rosetta
    choice=""
    while ! [[ "$choice" =~ ^[YyNn]$ ]]; do
      read -p "Do you want to install Rosetta to run x64 apps in addition to aarch64 ones? (y/n): " choice
    done
    if [[ "$choice" =~ ^[Yy]$ ]]; then
      softwareupdate --install-rosetta || true
    fi
  fi
}

install_nix() {
  # Check if running on Linux or macOS
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Running on Linux."

    # Check if systemd is available
    if [ "$(ps -p 1 -o comm=)" == "systemd" ]; then
      echo "Systemd is available. Installing Nix using Determinate Systems Nix Installer."
      curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    else
      echo "Systemd is not available. Installing Nix using official Nix installer."
      sh <(curl -L https://nixos.org/nix/install) --no-daemon

      # Configure support for Flakes
      mkdir -p ~/.config/nix
      echo "experimental-features = flakes nix-command" > ~/.config/nix/nix.conf
      . ~/.nix-profile/etc/profile.d/nix.fish
    fi

  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Running on macOS."

    # Ask user's preference for nix-darwin
      choice=""
    while ! [[ "$choice" =~ ^[YyNn]$ ]]; do
      read -p "Do you want to use nix-darwin to manage your system? When in doubt, choose yes. (y/n): " choice
    done

    if [[ "$choice" =~ ^[Yy]$ ]]; then
      echo "Installing Nix using official Nix installer for nix-darwin."
      sh <(curl -L https://nixos.org/nix/install) --daemon

      # Configure support for Flakes
      mkdir -p ~/.config/nix
      echo "experimental-features = flakes nix-command" > ~/.config/nix/nix.conf
    else
      echo "Installing Nix using Determinate Systems Nix Installer."
      curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    fi

    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

  else
    echo "Your operating system is not supported."
  fi
}

template() {
  FLAKE_DIR="$HOME/dotfiles"
  read -p "Where would you like to store your dotfiles? [~/dotfiles]: " input_dir
  if [ -n "$input_dir" ]; then
    FLAKE_DIR="$input_dir"
  fi
  if ! mkdir -p "$FLAKE_DIR" || ! cd "$FLAKE_DIR" || ! git init; then
    echo "Error: Could not create or write to directory $FLAKE_DIR"
    echo "Trying again... Press Ctrl-C to exit"
    template
    return
  fi
  nix flake init --template github:Cu3PO42/gleaming-glacier#system
  git add --all
  git commit -m "Init from template"
}

if [[ "$OSTYPE" == "darwin"* ]]; then
  choice=""
  while ! [[ "$choice" =~ ^[YyNn]$ ]]; do
    read -p "Would you like to install pre-requisites for macOS? If you choose no, things might break. (y/n): " choice
  done
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    mac_deps
  fi
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Git is not installed. Please install it and run this script again."
  exit 1
fi

if [[ "$1" == "--template" ]] && ! (git config user.name && git config user.email); then
  echo "To create a template, you need to configure your git user.name and user.email."
  echo "Please run 'git config user.name \"Your Name\"' and 'git config user.email \"your@email.com\"' and run this script again."
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  install_nix
fi

if [[ "$1" == "--template" ]]; then
  template
fi

exec $SHELL