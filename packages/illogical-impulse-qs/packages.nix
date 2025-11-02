# Package mappings from dots-hyprland meta-packages to nixpkgs
# Direct mapping from PKGBUILD files in arch-packages/
{ lib, pkgs }:

let
  # illogical-impulse-basic PKGBUILD
  basicPackages = with pkgs; [
    axel
    bc
    coreutils
    cliphist
    ddcutil
    cmake
    curl
    rsync
    wget
    ripgrep
    jq
    meson
    xdg-user-dirs
    kdePackages.kdialog
    imagemagick
    libnotify 


    fuzzel
    glib # for gsettings
    gsettings-desktop-schemas # GNOME schemas for non-GNOME environments
    networkmanagerapplet # nm-connection-editor
    translate-shell
    wlogout
    wl-clipboard
  ];

/*
  # illogical-impulse-python PKGBUILD (system dependencies)
  pythonSystemPackages = with pkgs; [
    clang
    # uv -> not needed in NixOS approach, we use pip directly
    gtk4
    libadwaita
    libsoup_3 # libsoup3
    libportal-gtk4
    gobject-introspection
    sassc
    opencv4 # python-opencv
    
    # Additional system libraries needed for Python packages
    stdenv.cc.cc.lib # provides libstdc++.so.6
    glibc
    zlib
    libffi
    openssl
    bzip2
    xz
    ncurses
    readline
    sqlite
  ];
  */

  # Additional packages that might be needed
  audioPackages = with pkgs; [
    pipewire
    wireplumber
    pavucontrol
    playerctl
  ];

  # Theme and appearance packages
  themePackages = with pkgs; [
    matugen # for Material You color generation
    # Additional theme packages as needed
  ];
in
{
  inherit 
    basicPackages 
    # pythonSystemPackages
    audioPackages
    themePackages;
  
  # Combined package sets for different use cases
  essentialPackages = basicPackages;
  
  allPackages = basicPackages ++ audioPackages ++ themePackages;
}
