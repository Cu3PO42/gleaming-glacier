# Nix derivation for iCalBuddy based on the Brew formula
# https://github.com/Homebrew/homebrew-core/blob/2f089a6f55a7496248be39f4d883094fd79cbdc4/Formula/ical-buddy.rb
# Originally written by yuanw at
# https://github.com/yuanw/nix-home/blob/ab1ab8c8bdbc018d105766a71a5732ded37cf18f/overlays/ical-buddy.nix
# Unfortunately, they did not expose the package in their flake, so I copied it over to mine.
{
  lib,
  stdenv,
  fetchFromGitHub,
  pkgs,
  ...
}: let
  frameworks = pkgs.darwin.apple_sdk.frameworks;
in
  stdenv.mkDerivation rec {
    pname = "icallBuddy";
    version = "1.10.1";

    src = fetchFromGitHub {
      owner = "dkaluta";
      repo = "icalBuddy64";
      rev = "v${version}";
      hash = "sha256-ID3U7lAve3DHTHx2kCunwg1LWkIEIIpQrXkvmkvn/Mg=";
    };

    buildInputs = [pkgs.perl frameworks.AppKit frameworks.Carbon frameworks.Cocoa frameworks.AddressBook frameworks.CalendarStore];
    buildPhase = ''
      # Allow native builds rather than only x86_64
      sed -i 's/-arch x86_64//g' Makefile
      make  icalBuddy icalBuddy.1 icalBuddyLocalization.1 icalBuddyConfig.1
    '';

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share/man/man1/
      cp icalBuddy $out/bin/icalBuddy
      mv *.1 $out/share/man/man1/
    '';

    meta = with lib; {
      description = "Get events and tasks from the macOS calendar database";
      homepage = "https://hasseg.org/icalBuddy/";
      platforms = platforms.darwin;
      license = licenses.mit;
    };
  }
